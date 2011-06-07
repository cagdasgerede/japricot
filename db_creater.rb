require 'rubygems'
require 'active_record'
 
class Zunit < ActiveRecord::Base
		
	validates_format_of :name, :with => /^[^\.]+$/, :on => :save # no period. 
	validates_presence_of :name, :package, :category, :origin
	validates_uniqueness_of :name, :scope => :package
	has_many :zmethods
	has_many :returned_by, :class_name => "Zreturn"
	has_many :returned_by_zmethods, :through => :returned_by, :source => 'zmethod'
	
	has_many :zparams
	has_many :used_by_zmethods, :through => :zparams, :source => 'owner'
	
	
	#This did not work: has_many :used_by_zunits, :through => :used_by_zmethods, :source => 'zreturn'
	#Therefore we have the following method.
	def used_by_zunits
		methods = used_by_zmethods
		res = []
		methods.each { |method|
			res << method.owner
		}
		res.uniq
	end
	
	def self.find_or_create params 
		z = Zunit.find(:first, 
			:conditions => {:package => params[:package], :name => params[:name]})
		if z.nil? or (z.category == 'unknown' and params[:category] != 'unknown')
			return Zunit.create!(params)
		else
			return z
		end
	end
	
	def self.cut_name_from_package full_name
		tmp = full_name.split( '.' )
		name = tmp.pop
		pkg = tmp.join( '.' )
		[name, pkg]
	end
end

class Zmethod < ActiveRecord::Base
	validates_presence_of :name, :category
	
	has_many :zparams
	has_one :zreturn
	belongs_to :owner, :class_name => 'Zunit', :foreign_key => 'zunit_id'
end 

class Zreturn < ActiveRecord::Base
	belongs_to :zunit
	belongs_to :zmethod
end

class Zparam < ActiveRecord::Base
	belongs_to :zunit
	belongs_to :owner, :class_name => 'Zmethod', :foreign_key => 'zmethod_id'
	validates_uniqueness_of :order, :scope => 'zmethod_id'
end


# load 'db_creater.rb'; DBCreater.init YAML.load_file(File.join('tests','yaml','file.yaml'))
class DBCreater
	
	@@db_file = ""
	
	def self.create db_file="#{File.expand_path( 'db.db', 'tmp' )}"
		ActiveRecord::Base.logger = Logger.new(STDERR)
		ActiveRecord::Base.colorize_logging = true
		ActiveRecord::Base.logger.level = Logger::ERROR #Logger::DEBUG
		
		@@db_file = db_file
		
		ActiveRecord::Base.establish_connection(
			:adapter => "sqlite3",
			:dbfile => @@db_file
			#:dbfile  => ":memory:"
		)
		clean
		_create_db
	end
	
	def self.clean
		File.delete @@db_file if File.exists? @@db_file
	end
	
	def self.init yaml, db_file="#{File.expand_path( 'db.db', 'tmp' )}"
		if $logger.nil?
			require 'logger'
			$logger = Logger.new STDOUT
			$logger.level = Logger::INFO 
		end
		create db_file
		insert yaml
	end
	
	# convert the parsing result of the parser to a database
	def self.insert hash
		hash.each_key do |klass_key|		
			s = ""
			klass = hash[klass_key]
			zunit_name = klass[:name]
			zunit_package = klass[:package]
			zunit_origin = klass[:origin]
			zunit_category = klass[:type].to_s

			zunit = Zunit.find_or_create({
				:name => zunit_name, 
				:package => zunit_package,
				:origin => zunit_origin,
				:category => zunit_category
			})
	
			klass[:methods].each do |method|
				s = "In #{zunit_category} #{zunit_package}::#{zunit_name} = "
				method_returns = method[:returns]
		
				# handle primitive types such int (add an auxiliary package)
				if method_returns.split('.').size == 1
					method_returns = "Primitive.#{method_returns}"
					mrcategory = 'primitive' 
				else
					mrcategory = 'unknown'
				end
				zname, zpkg = Zunit.cut_name_from_package method_returns

				method_returns_zunit = Zunit.find_or_create({
					:name => zname, 
					:package => zpkg,
					:origin => 'unknown',
					:category => mrcategory
				})
		
				method_name = method[:name]
				method_category = method[:type]
				if method_category.nil? #non-static methods
					method_category = 'instance_method'
				end
			
				zmethod = zunit.zmethods.create!(
					:name => method_name, 
					:category => method_category )
				zmethod.zreturn = Zreturn.create!(
					:zmethod=>zmethod, 
					:zunit=>method_returns_zunit)
				zmethod.save!
	
				s = "#{s}#{method_category} #{method_returns} #{method_name}("
				method[:params].each_with_index do |param, i|
				
					# handle primitive types such int (add an auxiliary package)
					if param.split('.').size == 1
						param = "Primitive.#{param}"
						pcategory = 'primitive' 
					else
						pcategory = 'unknown'
					end
					zmname, zmpkg = Zunit.cut_name_from_package param

					method_param_zunit = Zunit.find_or_create({
						:name => zmname, 
						:package => zmpkg,
						:origin => 'unknown',
						:category => pcategory
					})
			
					zmethod.zparams.create( :order => i+1, :zunit => method_param_zunit )
					
					s = "#{s}#{',' unless i==0} #{param}"
				end
				s = "#{s} ) found in #{zunit_origin}"
				$logger.debug s
			end
		end
	end
	

	private
	def self._create_db 
		ActiveRecord::Schema.define do
			create_table :zunits do |table|
				table.column :name, :string, :null => false
				table.column :package, :string, :null => false
				table.column :category, :string, :null => false
				table.column :origin, :string, :null => false
			end
	
			create_table :zmethods do |table|
				table.column :name, :string, :null => false
				table.column :zunit_id, :integer, :null => false
				table.column :category, :string, :null => false
			end
		
			create_table :zreturns do |table|
				table.column :zmethod_id, :integer, :null => false
				table.column :zunit_id, :integer, :null => false
			end
		
			create_table :zparams do |table|
				table.column :zmethod_id, :integer, :null => false
				table.column :zunit_id, :integer, :null => false
				table.column :order, :integer, :null => false
			end
		end
	end
end



