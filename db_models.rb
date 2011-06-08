class Zunit < ActiveRecord::Base
		
	validates_format_of :name, :with => /^[^\.]+$/, :on => :save # no period. 
	validates_presence_of :name, :package, :category, :origin
	validates_uniqueness_of :name, :scope => :package
	has_many :zmethods
	
	has_many :zparams #used as a param
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
	
	has_many :returned_by, :class_name => "Zreturn"
	has_many :returned_by_zmethods, :through => :returned_by, :source => 'zmethod'
	def returned_by_zunits
		methods = returned_by_zmethods
		res = []
		methods.each { |method|
			res << method.owner
		}
		res.uniq
	end
	
	def full_name
		"#{package}.#{name}"
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