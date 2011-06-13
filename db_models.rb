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
		""
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
		if z.nil?
			Zunit.create!(params)
		elsif (z.category == 'unknown' and params[:category] != 'unknown')
			Zunit.update(z, params)
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
	
	#see top_user
	def user_counts k=nil
		user_count = {}
		used_by_zunits.each { |user_unit|
			user_count[user_unit.full_name] = 0
		}

		used_by_zmethods.each { |user_method|
			user_count[user_method.owner.full_name] += 1
		}

		_prepare_hash_for_output user_count, k
	end
	
	#Unit consuming (having methods with parameter of) "me" the most
	def top_user
		user_counts[0]
	end
	
	#see top_returner
	def returner_counts k=nil
		returner_count= {}
		returned_by_zunits.each { |returner_unit|
			returner_count[returner_unit.full_name] = 0
		}

		returned_by_zmethods.each { |returner_method|
			returner_count[returner_method.owner.full_name] += 1
		}
		
		_prepare_hash_for_output returner_count, k
	end
	
	#Unit producing (having methods returning) "me" the most
	def top_returner
		returner_counts[0]
	end
	
	#see top_referrer
	def referrer_counts k=nil
		result = {}
		user_counts.each { |c|
			result[c[0]] = c[1]
		}
		returner_counts.each { |c|
			unless result[c[0]].nil?
				result[c[0]] += c[1]
			else
				result[c[0]] = c[1]
			end
		}
		
		_prepare_hash_for_output result, k
	end
	
	# Unit that consume and produce "me" (as method params and returns)
	def top_referrer
		referrer_counts[0]
	end
	
	# user_counts + returned_counts => referrer_counts
	# referrers(0) : all units referring to "me"
	# referrers(1) : all units referring to referrers(0) UNION referrers(0)
	def referrers(k=0)
		immediate_referrers = (used_by_zunits + returned_by_zunits).uniq
		if k == 0
			immediate_referrers.sort
		else
			unit_referrers = immediate_referrers 
			last_referrers = unit_referrers

			k.times { |i|
				break if last_referrers.empty?
				new_referrers = []
				last_referrers.each { |r|
					new_referrers += r.used_by_zunits
					new_referrers += r.returned_by_zunits
				}
				unit_referrers += new_referrers
				last_referrers = new_referrers
		
				unit_referrers.uniq!
				last_referrers.uniq!
			}
			unit_referrers.sort
		end
	end
	
	# see top_consumer
	def consuming_counts k=nil
		counts = {}
		zmethods.each { |m|
			res = m.zparams.collect { |p|
				p.zunit.full_name
			}
			unless res.nil?
				res.each { |name|
					if counts[name].nil?
						counts[name] = 1 
					else
						counts[name] += 1
					end
				}
			end
		}
		
		_prepare_hash_for_output counts, k
	end
	
	#see top_producer
	def producing_counts k=nil
		counts = {}
		zmethods.each { |m|
			name = m.zreturn.zunit.full_name
			if counts[name].nil?
				counts[name] = 1 
			else
				counts[name] += 1
			end
		}
		
		_prepare_hash_for_output counts, k 
	end
	
	#unit that "I" consume the most (most number of methods using that unit)
	def top_consuming
		consuming_counts[0]
	end
	
	#unit that "I" produce the most (most number of methods returning that unit)
	def top_producing
		producing_counts[0]
	end
	
	#units that "I" need, and (recursively) all units that are needed by those units.
	def needed k=0
		res = []
		Zunit._helper_for_needed_method self, res
		
		immediate_needed = res.uniq
		if k == 0
			immediate_needed.sort
		else
			unit_needed = immediate_needed 
			last_needed = unit_needed

			k.times { |i|
				break if last_needed.empty?
				new_needed = []
				last_needed.each { |n|
					Zunit._helper_for_needed_method n, new_needed 
				}
				unit_needed += new_needed
				last_needed = new_needed
		
				unit_needed.uniq!
				last_needed.uniq!
			}
			unit_needed.sort
		end
	end
	
	#units that refer to "me" and units that "I" need, and (recursively) all units that
	#refer or need these units (bounded by k).
	def neighbors k=0
		( referrers(k) + needed(k) ).uniq.sort
	end
	
	#all needed units (do not stop until closure is reached)
	def needed_closure
		needed( 9999999 ) #ok..this is a temporary hack.
	end
	
	#all referred units (do not stop until closure is reached)
	def referrers_closure
		referrers( 9999999 ) #ok..this is a temporary hack.
	end
	
	#all neigbor units (do not stop until closure is reached)
	def neighbors_closure
		neighbors( 9999999 ) #ok..this is a temporary hack.
	end
	
	def <=> unit
		full_name.capitalize <=> unit.full_name.capitalize
	end
	
	private
	def self._helper_for_needed_method unit, res
		unit.zmethods.each { |m|
			m.zparams.each { |p|
				res << p.zunit
			}
		}
		unit.zmethods.each { |m|
			res << m.zreturn.zunit
		}
	end

	def _prepare_hash_for_output hash, k
		result = hash.to_a

		result.sort! { |a,b|
			b[1] <=> a[1]
		}
		
		unless k.nil?
			result[0...k]
		else
			result
		end
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
	
	def <=> zmethod
		name <=> zmethod.name
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