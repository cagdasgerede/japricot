require "test/unit"
#require 'rubygems'
#require 'hpricot'
#require './folder_parser'
require 'db_manager'

class TestDBManager < Test::Unit::TestCase
	def setup
		if $logger.nil?
			require 'logger'
			$logger = Logger.new STDOUT
			$logger.level = Logger::INFO 
		end
		DBManager.set_db_file
		DBManager.clean
		DBManager.create
	end

	def test_single_result
		pkg = 'javax.swing.text.html'
		origin = 'test/classes/HTML.html'
		klass = 'HTML'
		ktype = 'class'
		mtype = 'static'
		mreturns = 'javax.swing.text.html.HTML.Tag[]'
		mname = 'getAllTags'
		param1Pkg = 'javax.swing.text'
		param1Klass = 'AttributeSet'
		param2Pkg = 'javax.swing.text.html.HTML'
		param2Klass = 'Attribute'
		param3 = 'int'
		
		hash = { 'javax.swing.text.html.HTML' => 
			{
				:name => klass,
				:package => pkg,
				:origin => origin,
				:type => ktype,
				:methods => [ {
					:type => mtype,
					:returns => mreturns,
					:name => mname,
					:params => [
						"#{param1Pkg}.#{param1Klass}",
						"#{param2Pkg}.#{param2Klass}",
						param3
					]
				} ]
			} 
		}

		DBManager.insert hash
		
		zunit = Zunit.find(:first, :conditions => { 
			:name=>klass, 
			:package=>pkg,
			:origin=>origin,
			:category=>ktype
			} )
		
		assert_not_equal(zunit, nil )
		
		method = zunit.zmethods.find(:first, :conditions => {
				:name => mname,
				:category=> mtype
			})
		assert_not_nil( method )
		
		mreturn = method.zreturn.zunit
		assert_equal(
			"#{mreturn.package}.#{mreturn.name}",
			mreturns)

		method.zparams.each do |zparam|
			if zparam.zunit.name == param1Klass
				assert_equal(param1Pkg,zparam.zunit.package)
			elsif zparam.zunit.name == param2Klass
				assert_equal(param2Pkg,zparam.zunit.package)
			elsif zparam.zunit.name == param3
				assert_equal('Primitive',zparam.zunit.package)
			else
				assert(false)
			end
		end
	end
	
	def test_folder_all
		_test_against_yaml File.join( 'tests', 'yaml', 'folder_all.yaml' )
		assert_equal(7,Zunit.find(:all, :conditions=>[" origin <> ?" , 'unknown']).size)
		
		assert_equal(1, Zunit.find(:all, :conditions=> {:package => 'net.rim.device.api.system',
			:name => 'AlertListener'}).size)
		
		assert_equal(3,Zunit.find(:first, :conditions=> {:package => 'net.rim.device.api.system',
			:name => 'AlertListener'}).zmethods.size)
			
		# void methods	
		void = Zunit.find_by_name('void')
		assert_equal(10, void.returned_by_zmethods.count)
		
		# methods returning boolean
		boolean = Zunit.find_by_name('boolean')
		assert_equal(1, boolean.returned_by_zmethods.count)
		
		# methods returning string
		string = Zunit.find_by_name_and_package('String', 'java.lang')
		assert_equal(2, string.returned_by_zmethods.count)
		
		#methods accepting string as parameter
		assert_equal(3, string.used_by_zmethods.count)
		
		#classes/interfaces accepting string as parameter in their methods
		assert_equal(2, string.used_by_zunits.size)
		
	end
	
=begin TO BE COMPLETED
	def test_file
		_test_against_yaml File.join( 'tests', 'yaml', 'file.yaml' )
	end

	def _test_files
		_test_against_yaml File.join( 'tests', 'yaml', 'files.yaml' )
	end

	def _test_folder
		_test_against_yaml File.join( 'tests', 'yaml', 'folder.yaml' )
	end
=end	
	def _test_against_yaml file_path
		yaml = YAML.load_file file_path
		$logger.debug yaml.to_yaml
		DBManager.insert yaml
	end
end

