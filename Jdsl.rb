load 'db_manager.rb'

class JDSL
	
	#find k distance classes to "java.lang.String"
	def self.k_referrers k, unit_name, pkg
		unit = Zunit.find_by_name_and_package(unit_name, pkg)
		unit.referrers(k)
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
		unless unit.nil? 
			unit.top_user
		else
			nil
		end
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
	
	def self.setup db_file, source_yaml
		unless File.exists? db_file
			DBManager.init( 
				YAML.load_file( source_yaml ),
				db_file
			)
		else
			DBManager.connect db_file
		end
	end
	
	#sample run
	def self.sample_run
		# methods returning string
		string = Zunit.find_by_name_and_package('String', 'java.lang')
		puts string.returned_by_zmethods.count
				
		#methods accepting string as parameter
		puts string.used_by_zmethods.count
		
		#classes/interfaces accepting string as parameter in their methods
		puts string.used_by_zunits.size
	end
end

#JDSL.test_setup
#JDSL.sample_run

#x = JDSL.k_referrers 2, 'String', 'java.lang'
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
		#res = ""
		each { |e|
			#res += "#{e.print}\n"
			e.print
			}
		#res
		""
	end
end

def nil.print 
	puts "empty result"
end

class String
	#"HTML".jmethods(:returns=>"javax.swing.text.html.HTML.Tag")
	# => getTag
	def jmethods( conditions={} )
		units = candidates()
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
	
	def referrers
		unit = candidates().first
		unless unit.nil?
			unit.referrers
		else
			[]
		end
	end
	
	def jmethod name
		unit = candidates().first
		unless unit.nil?
			unit.zmethods.find_by_name(name)
		else
			nil
		end
	end
	
	def jclass
		candidates().first
	end
	
	def print
		puts inspect
	end
end

class Fixnum
	def print
		puts inspect
	end
end

def execute command
	puts
	puts "#{command} => "
	#puts 
	instance_eval(command)
	puts
end

def execute_return command
	puts
	puts "#{command} => "
	puts instance_eval(command)
end

def all_user_counts
	cs = ''.allcandidates.sort
	
	cs.each_with_index { |c,i|
		counts = c.user_counts
		if counts.size == 0
			puts "#{c.full_name} is used by no unit"
		else
			if counts.size > 1
				puts "#{c.full_name} is used by these"
			else
				puts "#{c.full_name} is used by this"
			end
			puts c.user_counts.inspect
		end
		puts "---------------"
	}
	""
end


##############################################
## JDSL USAGE EXAMPLES				##########
##								##############
##						######################
##############################################

#execute_return("\"\".allcandidates.print")
##javax.swing.text.html.HTML
##javax.swing.text.html.HTML.Tag[]
##javax.swing.text.html.HTML.Tag
##java.lang.String
##Primitive.int
##javax.swing.text.AttributeSet
##javax.swing.text.html.HTML.Attribute
##javax.swing.text.html.HTML.Attribute[]
##Primitive.void
##Primitive.byte[]
##net.rim.device.api.barcodelib.BarcodeDecoder
##org.w3c.dom.views.AbstractView
##org.w3c.dom.views.DocumentView
##java.util.zip.ZipFile
##java.util.zip.ZipEntry
##java.io.InputStream
##java.util.Enumeration
##java.util.Collection
##com.google.zxing.qrcode.encoder.BitVector
##net.rim.device.api.system.AccelerometerSensor
##Primitive.boolean
##net.rim.device.api.system.AccelerometerSensor.Channel
##net.rim.device.api.system.Application
##net.rim.device.api.system.AccelerometerChannelConfig
##net.rim.device.api.system.AlertListener


#execute('\'\'.allcandidates.sort.print')
##''.allcandidates.sort.print => 
##com.google.zxing.qrcode.encoder.BitVector
##java.io.InputStream
##java.lang.String
##java.util.Collection
##java.util.Enumeration
##java.util.zip.ZipEntry
##java.util.zip.ZipFile
##javax.swing.text.AttributeSet
##javax.swing.text.html.HTML
##javax.swing.text.html.HTML.Attribute
##javax.swing.text.html.HTML.Attribute[]
##javax.swing.text.html.HTML.Tag
##javax.swing.text.html.HTML.Tag[]
##net.rim.device.api.barcodelib.BarcodeDecoder
##net.rim.device.api.system.AccelerometerChannelConfig
##net.rim.device.api.system.AccelerometerSensor
##net.rim.device.api.system.AccelerometerSensor.Channel
##net.rim.device.api.system.AlertListener
##net.rim.device.api.system.Application
##org.w3c.dom.views.AbstractView
##org.w3c.dom.views.DocumentView
##Primitive.boolean
##Primitive.byte[]
##Primitive.int
##Primitive.void


#execute_return("\"\".allcandidates[0].print")
##"".allcandidates[0].print => 
##javax.swing.text.html.HTML

#execute_return("\"String\".allcandidates.inspect")
##"String".allcandidates.inspect => 
##[#<Zunit id: 4, name: "String", package: "java.lang", category: "unknown", origin: "unknown">]


#execute("\"String\".allcandidates.print")
##"String".allcandidates.print => 
##java.lang.String

#execute("\"String\".allcandidates.first.full_name.referrers.print")
##"String".allcandidates.first.full_name.referrers.print => 
##javax.swing.text.html.HTML
##java.util.zip.ZipFile
##com.google.zxing.qrcode.encoder.BitVector

#execute("\"String\".referrers.print")
##"String".referrers.print => 
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

#execute_return( "\"HTML\".jmethods(:name=>\"getTag\").first.void?" )
##"HTML".jmethods(:name=>"getTag").first.void? => 
##false

#execute_return( "\"HTML\".jmethods(:name=>\"getTag\").first.param_count")
##"HTML".jmethods(:name=>"getTag").first.param_count => 
##1

#execute( "\"HTML\".jmethod(\"getTag\").print" )
## "HTML".jmethod("getTag").print => 
## javax.swing.text.html.HTML static :: javax.swing.text.html.HTML.Tag  getTag( java.lang.String )

#execute_return( "\"HTML\".jclass.full_name" )
##"HTML".jclass.full_name => 
##javax.swing.text.html.HTML

#execute( '\'java.lang.String\'.jclass.referrers(0).print' )
##'java.lang.String'.jclass.referrers(0).print => 
##javax.swing.text.html.HTML
##java.util.zip.ZipFile
##com.google.zxing.qrcode.encoder.BitVector

#execute_return( '\'java.lang.String\'.jclass.top_user[0]' )
##'java.lang.String'.jclass.top_user[0] => 
##javax.swing.text.html.HTML

#execute_return( '\'java.lang.String\'.jclass.top_user[1]' )
##'java.lang.String'.jclass.top_user[1] => 
##2

## INSPECT VS. PRINT
#execute_return( '\'java.lang.String\'.jclass.user_counts.inspect' )
##'java.lang.String'.jclass.user_counts.print => 
##[["javax.swing.text.html.HTML", 2], ["java.util.zip.ZipFile", 1]]

#execute( '\'java.lang.String\'.jclass.user_counts.print' )
##'java.lang.String'.jclass.user_counts.print => 
##"javax.swing.text.html.HTML"
##2
##
##"java.util.zip.ZipFile"
##1

#execute_return( '\'java.lang.String\'.jclass.user_counts[0].inspect' )
##'java.lang.String'.jclass.user_counts[0].inspect => 
##["javax.swing.text.html.HTML", 2]

#execute_return( '\'java.lang.String\'.jclass.user_counts[0][0].inspect' )
##'java.lang.String'.jclass.user_counts[0][0].inspect => 
#"javax.swing.text.html.HTML"

#execute_return( 'all_user_counts' )
##all_user_counts => 
##com.google.zxing.qrcode.encoder.BitVector is used by this
##[["com.google.zxing.qrcode.encoder.BitVector", 2]]
##---------------
##java.io.InputStream is used by no unit
##---------------
##java.lang.String is used by these
##[["javax.swing.text.html.HTML", 2], ["java.util.zip.ZipFile", 1]]
##---------------
##java.util.Collection is used by this
##[["java.util.zip.ZipFile", 1]]
##---------------
##java.util.Enumeration is used by no unit
##---------------
##java.util.zip.ZipEntry is used by this
##[["java.util.zip.ZipFile", 1]]
##---------------
##java.util.zip.ZipFile is used by no unit
##---------------
##javax.swing.text.AttributeSet is used by this
##[["javax.swing.text.html.HTML", 1]]
##---------------
##javax.swing.text.html.HTML is used by no unit
##---------------
##javax.swing.text.html.HTML.Attribute is used by this
##[["javax.swing.text.html.HTML", 1]]
##---------------
##javax.swing.text.html.HTML.Attribute[] is used by no unit
##---------------
##javax.swing.text.html.HTML.Tag is used by no unit
##---------------
##javax.swing.text.html.HTML.Tag[] is used by no unit
##---------------
##net.rim.device.api.barcodelib.BarcodeDecoder is used by no unit
##---------------
##net.rim.device.api.system.AccelerometerChannelConfig is used by this
##[["net.rim.device.api.system.AccelerometerSensor", 1]]
##---------------
##net.rim.device.api.system.AccelerometerSensor is used by no unit
##---------------
##net.rim.device.api.system.AccelerometerSensor.Channel is used by no unit
##---------------
##net.rim.device.api.system.AlertListener is used by no unit
##---------------
##net.rim.device.api.system.Application is used by this
##[["net.rim.device.api.system.AccelerometerSensor", 3]]
##---------------
##org.w3c.dom.views.AbstractView is used by no unit
##---------------
##org.w3c.dom.views.DocumentView is used by no unit
##---------------
##Primitive.boolean is used by no unit
##---------------
##Primitive.byte[] is used by this
##[["javax.swing.text.html.HTML", 1]]
##---------------
##Primitive.int is used by these
##[["com.google.zxing.qrcode.encoder.BitVector", 4], ["net.rim.device.api.system.AlertListener", 3], ["javax.swing.text.html.HTML", 1]]
##---------------
##Primitive.void is used by no unit
##---------------


