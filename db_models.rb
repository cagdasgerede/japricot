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
	
	def print
		full_name
	end
	
	def full_name
		"#{package}.#{name}"
	end
	
	# either just class or package.class (e.g., String or java.lang.String)
	def self.find_all_by_semifull_name semi_full_name
		name, pkg = cut_name_from_package semi_full_name
		
		if pkg.empty? 
			Zunit.find_all_by_name(name) 
		else 
			Zunit.find_all_by_name_and_package(name, pkg)
		end
	end
	
	def self.find_all_by_substring substring
		name, pkg = cut_name_from_package substring
		
		res1 = Zunit.find(:all, :conditions => [ "name LIKE ?", "%#{name}%" ])
		if pkg.empty? 
			res2 = Zunit.find(:all, :conditions => [ "package LIKE ?", "%#{name}%" ])
			res1 + res2
		else
			res2 = res1.find_all { |unit|
				not (unit.package =~ /#{pkg}$/).nil?
			}
			res3 = Zunit.find(:all, :conditions => [ "package LIKE ?", "%#{pkg}.#{name}%"] )
			res2 + res3
		end
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
	
	def print
		params = ""
		zparams.each_with_index { |x, i| params += "#{x.print}#{', ' if i+1<zparams.size}" } 
		"#{owner.print} #{ category if category == 'static' } :: #{zreturn.print}  #{name}( #{params} )"
	end
	
	def void?
		zreturn.nil?
	end
	
	def param_count
		zparams.size
	end
end 

class Zreturn < ActiveRecord::Base
	belongs_to :zunit
	belongs_to :zmethod
	
	def print
		"#{zunit.print}"
	end
end

class Zparam < ActiveRecord::Base
	belongs_to :zunit
	belongs_to :owner, :class_name => 'Zmethod', :foreign_key => 'zmethod_id'
	validates_uniqueness_of :order, :scope => 'zmethod_id'
	
	def print
		"#{zunit.print}"
	end
end