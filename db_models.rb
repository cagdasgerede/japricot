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
		puts full_name
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
	
	def neighbors(k=0)
		if k == 0
			(used_by_zunits + returned_by_zunits).uniq
		else
			unit_neighbors = used_by_zunits
			last_neighbors = unit_neighbors

			(k-1).times { |i|
				break if last_neighbors.empty?
				new_neighbors = []
				last_neighbors.each { |neighbor|
					new_neighbors += neighbor.used_by_zunits
				}
				unit_neighbors += new_neighbors
				last_neighbors = new_neighbors
		
				unit_neighbors.uniq!
				last_neighbors.uniq!
			}
			unit_neighbors
		end
	end
	
	def use_counts
		use_count = {}
		used_by_zunits.each { |user_unit|
			use_count[user_unit.full_name] = 0
		}

		used_by_zmethods.each { |user_method|
			use_count[user_method.owner.full_name] += 1
		}

		result = use_count.to_a

		result.sort! { |a,b|
			b[1] <=> a[1]
		}

		result
	end
	
	def top_user
		use_counts[0]
	end
end

class Zmethod < ActiveRecord::Base
	validates_presence_of :name, :category
	
	has_many :zparams
	has_one :zreturn
	belongs_to :owner, :class_name => 'Zunit', :foreign_key => 'zunit_id'
	
	def print
		params = ""
		zparams.each_with_index { |param, i| params += "#{param.zunit.full_name}#{', ' if i+1 < zparams.size}" } 
		puts "#{owner.full_name} #{ category if category == 'static' } :: #{zreturn.zunit.full_name}  #{name}( #{params} )"
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
end

class Zparam < ActiveRecord::Base
	belongs_to :zunit
	belongs_to :owner, :class_name => 'Zmethod', :foreign_key => 'zmethod_id'
	validates_uniqueness_of :order, :scope => 'zmethod_id'
end