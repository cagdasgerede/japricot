load 'db_manager.rb'

class JDSL
	
	def self.run
		# methods returning string
		string = Zunit.find_by_name_and_package('String', 'java.lang')
		puts string.returned_by_zmethods.count
				
		#methods accepting string as parameter
		puts string.used_by_zmethods.count
		
		#classes/interfaces accepting string as parameter in their methods
		puts string.used_by_zunits.size
	end
	
	#find k distance classes to "java.lang.String"
	def self.k_neighbors k, unit_name, pkg
		unit = Zunit.find_by_name_and_package(unit_name, pkg)
		unit_neighbors = unit.used_by_zunits
		last_neighbors = unit_neighbors

		(k-1).times { |i|
			puts i
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
	
	#top_k returned class
	def self.top_k_returned k
		list = []
		Zunit.find(:all).each { |unit|
			list << [ unit.returned_by_zunits.size, unit.full_name]
		}
		list.sort!
		list.reverse!
		#units.sort! { |a,b| a.returned_by_zunits.size <=> b.returned_by_zunits.size }
		list[0...k]
	end
	
	#top_k_used units (a unit is used by another unit if
	#the former is a parameter of the latter.)
	def self.top_k_used k
		list = []
		Zunit.find(:all).each { |unit|
			list << [ unit.used_by_zmethods.size, unit.full_name]
		}
		list.sort!
		list.reverse!
		puts list[0...k]
	end
	
	#given a unit, tell me which unit is top user of the former.
	#a unit is used by another if former is a parameter in a method of latter
	def self.top_user_of unit_name, package
		unit = Zunit.find_by_name_and_package( unit_name, package )
		use_count = {}
		unit.used_by_zunits.each { |user_unit|
			use_count[user_unit.full_name] = 0
		}

		unit.used_by_zmethods.each { |user_method|
			use_count[user_method.owner.full_name] += 1
		}

		result = use_count.to_a

		result.sort! { |a,b|
			b[1] <=> a[1]
		}

		result[0] #top
		#puts result.to_yaml
	end
	
	def self.top_users_of_all
		#top user of all
		top_users = []
		Zunit.find(:all).each { |unit|
			top_user = JDSL.top_user_of( unit.name, unit.package )
			unless top_user.nil?
				top_users << [unit.full_name] + [top_user]
			end
		}
		top_users
	end
	
	def self.never_used_units among=Zunit.find(:all)
		never_used = []
		among.each { |unit|
			if unit.used_by_zunits.empty?
				never_used << unit
			end
		}	
		never_used
	end
	
	def self.never_returned_units among=Zunit.find(:all)
		never_returned = []
		among.each { |unit|
			if unit.returned_by.empty?
				never_returned << unit
			end
		}	
		never_returned
	end
	
	def self.never_used_and_returned_units among=Zunit.find(:all)
		JDSL.never_used_units( JDSL.never_returned_units )
	end
	
	def self.test_setup
		db_file = "#{File.expand_path( 'jdsl.db', 'tmp' )}"
		unless File.exists? db_file
			DBManager.init( 
				YAML.load_file( File.join( 'tests', 'yaml', 'folder_all.yaml' ) ),
				db_file
			)
		else
			DBManager.connect db_file
		end
	end
end

JDSL.test_setup
#JDSL.run

#x = JDSL.k_neighbors 2, 'String', 'java.lang'
#puts x.to_yaml


#x = JDSL.top_k_returned 5
#puts x 

#x = JDSL.top_k_used 5
#puts x
	
#x = JDSL.top_user_of 'int', 'Primitive'
#puts "int uses #{x[0]} #{x[1]} times"

#top_users = JDSL.top_users_of_all
#puts top_users.sort.to_yaml

#never_used = JDSL.never_used_units
#puts never_used.to_yaml
#puts never_used.size

#never_returned = JDSL.never_returned_units
#puts never_returned_units.to_yaml

#never_used_and_returned = JDSL.never_used_and_returned_units
#puts never_used_and_returned.size
class Array
	def collect_names
		collect { |unit|
			if unit.respond_to? 'full_name'
				unit.full_name 
			else
				unit.name
			end
				}.uniq
	end
	
	def print
		res = ""
		each { |e|
			res += "#{e.print}\n"
			}
		res
	end
end

def nil.print 
	"empty result"
end

class String
	#"HTML".jmethods(:returns=>"javax.swing.text.html.HTML.Tag")
	# => getTag
	def jmethods( conditions={} )
		units = Zunit.find_all_by_semifull_name self
		if units.empty?
			[]
		else
			methods = units.first.zmethods
			if conditions != {}
				returns = conditions[:returns]
				if returns != nil
					returns = returns.gsub('[', '\[')
					returns = returns.gsub(']', '\]')
					methods = methods.select{ |method|
						nil != (method.zreturn.zunit.full_name =~ /#{returns}$/)
					}
				end
				name = conditions[:name]
				if name != nil
					methods = methods.select { |method|
						method.name == name
					}
				end
			end
			methods
		end
	end
	
	def candidates
		Zunit.find_all_by_semifull_name(self)
	end
	
	def allcandidates
		Zunit.find_all_by_substring( self ).uniq
	end
	
	def neighbors
		unit = Zunit.find_all_by_semifull_name(self).first
		unless unit.nil?
			( unit.used_by_zunits +
			unit.returned_by_zunits ).uniq
		else
			[]
		end
	end
	
	def jmethod name
		unit = Zunit.find_all_by_semifull_name(self).first
		unit.zmethods.find_by_name(name)
	end
end

def execute command
	puts
	puts "#{command} => "
	puts instance_eval(command)
	puts
end

#execute("\"String\".allcandidates.first.full_name.neighbors.print")
##"String".allcandidates.first.full_name.neighbors.print => 
##javax.swing.text.html.HTML
##java.util.zip.ZipFile
##com.google.zxing.qrcode.encoder.BitVector

#execute("\"String\".neighbors.print")
##"String".neighbors.print => 
##javax.swing.text.html.HTML
##java.util.zip.ZipFile
##com.google.zxing.qrcode.encoder.BitVector

#execute( "\"HTML\".jmethods.print")
#"HTML".jmethods.print => 
#javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Tag[]  getAllTags(  )
#javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Tag  getTag( java.lang.String )
#javax.swing.text.html.HTML static :: Primitive.int  getIntegerAttributeValue( javax.swing.text.AttributeSet, javax.swing.text.html.HTML.Attribute, Primitive.int )
#javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Attribute[]  getAllAttributeKeys(  )
#javax.swing.text.html.HTML  :: Primitive.void  setExtra( Primitive.byte[] )
#javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Attribute  getAttributeKey( java.lang.String )


#execute( "\"HTML\".jmethods(:returns=>\"Tag\").first.print" )
##"HTML".jmethods(:returns=>"Tag").first.print => 
##javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Tag  getTag( java.lang.String )

#execute( "\"HTML\".jmethods(:returns=>\"Attribute\").first.print" )
##"HTML".jmethods(:returns=>"Attribute").first.print => 
##javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Attribute  getAttributeKey( java.lang.String )

#execute( "\"HTML\".jmethods(:returns=>\"Attribute[]\").first.print" )
##"HTML".jmethods(:returns=>"Attribute[]").first.print => 
##javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Attribute[]  getAllAttributeKeys(  )

#execute( "\"HTML\".jmethods(:name=>\"getTag\").first.print" )
##"HTML".jmethods(:name=>"getTag", :returns => \"HTML.Tag\").first.print => 
##javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Tag  getTag( java.lang.String )

#execute( "\"HTML\".jmethods(:name=>\"getTag\").first.void?" )
##"HTML".jmethods(:name=>"getTag").first.void? => 
##false

#execute( "\"HTML\".jmethods(:name=>\"getTag\").first.param_count")
##"HTML".jmethods(:name=>"getTag").first.param_count => 
##1

#execute( "\"HTML\".jmethod(\"getTag\").print" )
## "HTML".jmethod("getTag").print => 
## javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Tag  getTag( java.lang.String )

