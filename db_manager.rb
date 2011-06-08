require 'rubygems'
require 'active_record'
require 'db_models'

# load 'db_manager.rb'; DBCreater.init YAML.load_file(File.join('tests','yaml','file.yaml'))
class DBManager
	
	def self.set_db_file file="#{File.expand_path( 'db.db', 'tmp' )}"
		@@db_file = file
	end
	
	def self.connect db_file=@@db_file
		ActiveRecord::Base.logger = Logger.new(STDERR)
		ActiveRecord::Base.colorize_logging = true
		ActiveRecord::Base.logger.level = Logger::ERROR #Logger::DEBUG
		
		ActiveRecord::Base.establish_connection(
			:adapter => "sqlite3",
			:database => db_file
		)
	end

	
	def self.create db_file=@@db_file
		connect db_file
		_create_db
	end
	
	def self.clean db_file=@@db_file
		File.delete db_file if File.exists? db_file
	end
	
	def self.init yaml, db_file
		if $logger.nil?
			require 'logger'
			$logger = Logger.new STDOUT
			$logger.level = Logger::INFO 
		end
		set_db_file db_file
		clean
		create
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



