require 'db_manager'

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


x = JDSL.top_k_returned 5
puts x 

