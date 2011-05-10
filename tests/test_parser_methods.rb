require "test/unit"
require 'rubygems'
require 'hpricot'
require './parser'
require './tests/test_helper'

class TestParserMethods < Test::Unit::TestCase

	METHOD_TEST_FOLDER = File.join('tests','methods')
	
	def _test config
		doc = Parser.prepare config[:file]
		method = {}
		Parser.parse_single doc, method
		_assert config, method
	end

	def _folder_helper file
		File.join(METHOD_TEST_FOLDER, file)
	end

	def test_Test1
		config = {:file => _folder_helper('Test1.txt'),
			:method => 'format',
			:params => ["java.util.Locale", "java.lang.String", "java.lang.Object..."],
			:returns => "java.lang.String",
			:type => 'static' }
		_test config
	end

	def test_Test2
		config = {:file => _folder_helper('Test2.txt'),
			:method => 'valueOf',
			:params => ["java.lang.Object"],
			:returns => 'java.lang.String',
			:type => 'static'}
		_test config
	end

	def test_Test3
		config = {:file => _folder_helper('Test3.txt'),
			:method => 'valueOf',
			:params => ["char[]"],
			:returns => 'java.lang.String',
			:type => 'static' }
		_test config
	end

	def test_Test4
		config = {:file => _folder_helper('Test4.txt'),
			:method => 'valueOf',
			:params => ["long"],
			:returns => 'java.lang.String',
			:type => 'static' }
		_test config
	end

	def test_Test5
		config = {:file => _folder_helper('Test5.txt'),
			:method => 'intern',
			:params => [],
			:returns => 'java.lang.String' }
		_test config
	end

	def test_Test6
		config = {:file => _folder_helper('Test6.txt'),
			:method => 'indexOf',
			:params => ["java.lang.String", "int"],
			:returns => 'int'}
		_test config
	end

	def test_Test7
		config = {:file => _folder_helper('Test7.txt'),
			:method => 'isEmpty',
			:params => [],
			:returns => 'boolean' }
		_test config
	end

	def test_Test8
		config = {:file => _folder_helper('Test8.txt'),
			:method => 'create',
			:params => ["net.rim.device.api.system.Bitmap"],
			:returns => 'net.rim.device.api.ui.Graphics',
			:type => 'static' }
		_test config
	end

	def test_Test9
		config = {:file => _folder_helper('Test9.txt'),
			:method => 'clear',
			:params => [],
			:returns => 'void' }
		_test config
	end  
end
