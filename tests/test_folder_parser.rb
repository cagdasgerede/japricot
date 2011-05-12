require "test/unit"
require 'rubygems'
require 'hpricot'
require './folder_parser'

class TestFolderParser < Test::Unit::TestCase
	def setup
		if $logger.nil?
			require 'logger'
			$logger = Logger.new STDOUT
			$logger.level = Logger::ERROR
		end
	end

	# this test causes a log message of type FATAL. This is expected.
	def test_parse_file_empty
		assert_equal( {}, FolderParser.parse_file(File.join('tests', 'classes', 'UnrelatedFile.html')))
	end
	
	def test_unmatching_class_name_vs_file_name
		assert_raise Exception do FolderParser.parse_file(File.join('tests','classes','UnmatchingClass.html')) end
	end

	def _helper params
		pkg_and_name, extracted = FolderParser.parse_file(File.join('tests','classes',"#{params[:name]}.html")).shift
		assert_equal( params[:name], extracted[:name], "Class name mismatch" )
		assert_equal( params[:package], extracted[:package], "Package name mismatch" )
		assert_equal( File.join('tests','classes',"#{params[:name]}.html"), extracted[:origin], "Origin file mismatch" )
		assert_equal( params[:method_count], extracted[:methods].length, "Number of methods mismatch" )
		assert_equal( params[:type], extracted[:type], "Unit type mismatch")
	end

	def test_parse_file_HTML
		params = { :name => 'HTML',
		:package => 'javax.swing.text.html',
		:method_count => 6,
		:type => :class }
		
		_helper params
	end
	
	def test_parse_file_AccelerometerSensor
		params = { :name => 'AccelerometerSensor',
		:package => 'net.rim.device.api.system',
		:method_count => 4,
		:type => :class }
		
		_helper params
	end

	def test_parse_file_BarcodeDecoder
		params = {:name => 'BarcodeDecoder',
		:package => 'net.rim.device.api.barcodelib',
		:method_count => 0,
		:type => :class }
		
		_helper params
	end
	
	def test_parse_file_BitVector
		params = {:name => 'BitVector',
		:package => 'com.google.zxing.qrcode.encoder',
		:method_count => 9,
		:type => :class }
		
		_helper params
	end
	
	def test_parse_file_ZipFile
		params = {:name => 'ZipFile',
		:package => 'java.util.zip',
		:method_count => 8,
		:type => :class }
		
		_helper params
	end
	
	def test_parse_file_AbstractView
		params = {:name => 'AbstractView',
		:package => 'org.w3c.dom.views',
		:method_count => 1,
		:type => :interface }
		
		_helper params
	end
	
	def test_parse_file_AlertListener
		params = {:name => 'AlertListener',
		:package => 'net.rim.device.api.system',
		:method_count => 3,
		:type => :interface }
		
		_helper params
	end
	
	def test_parse_files
		res = FolderParser.parse_files [File.join('tests','classes','HTML.html'), File.join('tests','classes','AbstractView.html')]
		html = res["javax.swing.text.html.HTML"]
		assert_equal(html[:type], :class)
		assert_equal(html[:origin], "tests/classes/HTML.html")
		assert_equal(html[:name], "HTML")
		assert_equal(html[:package], "javax.swing.text.html")
		
		abstract_view = res["org.w3c.dom.views.AbstractView"]
		assert_equal(abstract_view[:type], :interface)
		assert_equal(abstract_view[:origin], "tests/classes/AbstractView.html")
		assert_equal(abstract_view[:name], "AbstractView")
		assert_equal(abstract_view[:package], "org.w3c.dom.views")
	end
end

