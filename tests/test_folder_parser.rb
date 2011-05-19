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

	def test_parse_file_empty
		assert_equal( {}, FolderParser.parse_file(File.join('tests', 'classes', 'UnrelatedFile.html')))
	end
	
	def test_unmatching_class_name_vs_file_name
		# this test would trigger a log message of type ERROR. We raise the level to FATAL temporarily to ignore this message.
		original = $logger.level
		$logger.level = Logger::FATAL
		assert_raise Exception do FolderParser.parse_file(File.join('tests','classes','UnmatchingClass.html')) end
		$logger.level = original
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
		assert_equal(html[:methods].size, 6)

		
		abstract_view = res["org.w3c.dom.views.AbstractView"]
		assert_equal(abstract_view[:type], :interface)
		assert_equal(abstract_view[:origin], "tests/classes/AbstractView.html")
		assert_equal(abstract_view[:name], "AbstractView")
		assert_equal(abstract_view[:package], "org.w3c.dom.views")
		assert_equal(abstract_view[:methods].size, 1)
	end
	
	def test_parse_folder
		res = FolderParser.parse_folder File.join('tests','folders','1', 'classes')
		html = res["javax.swing.text.html.HTML"]
		assert_equal(html[:type], :class)
		assert_equal(html[:origin], "tests/folders/1/classes/HTML.html")
		assert_equal(html[:name], "HTML")
		assert_equal(html[:package], "javax.swing.text.html")
		assert_equal(html[:methods].size, 6)

		
		abstract_view = res["org.w3c.dom.views.AbstractView"]
		assert_equal(abstract_view[:type], :interface)
		assert_equal(abstract_view[:origin], "tests/folders/1/classes/AbstractView.html")
		assert_equal(abstract_view[:name], "AbstractView")
		assert_equal(abstract_view[:package], "org.w3c.dom.views")
		assert_equal(abstract_view[:methods].size, 1)
		
		assert_equal(res.size, 2)
	end
	
	def test_extract_subfolders_recursively
		res = FolderParser.extract_subfolders_recursively File.join( 'tests', 'extract_folders_recursively')
		expected =%w(
			tests/extract_folders_recursively/x1 
			tests/extract_folders_recursively/x1/x1x1
			tests/extract_folders_recursively/x1/x1x1/x1x1x1
			tests/extract_folders_recursively/y1
			tests/extract_folders_recursively/y1/y1y1
			tests/extract_folders_recursively/y1/y1z1)

		assert( res.sort == expected )
	end
	
	def test_parse_recursively 
		res = FolderParser.parse_recursively File.join('tests', 'recursive')
		assert_equal(res.keys.size, 7)
		
		barcode ={
		:type=>:class,
		:methods=>[],
		:origin=>"tests/recursive/net/rim/device/api/barcodelib/BarcodeDecoder.html",
		:name=>"BarcodeDecoder",
		:package=>"net.rim.device.api.barcodelib"}
		
		assert( barcode == res[ 'net.rim.device.api.barcodelib.BarcodeDecoder' ] )
		
		html ={
		:type=>:class,
		:methods=>[
			{:type=>"static", :params=>[], :name=>"getAllTags", :returns=>"javax.swing.text.html.HTML.Tag[]"},
			{:type=>"static", :params=>["java.lang.String"], :name=>"getTag", :returns=>"javax.swing.text.html.HTML.Tag"},
			{:type=>"static", :params=>["javax.swing.text.AttributeSet", "javax.swing.text.html.HTML.Attribute", "int"], :name=>"getIntegerAttributeValue", :returns=>"int"},
			{:type=>"static", :params=>[], :name=>"getAllAttributeKeys", :returns=>"javax.swing.text.html.HTML.Attribute[]"}, {:params=>["byte[]"], :name=>"setExtra", :returns=>"void"},
			{:type=>"static", :params=>["java.lang.String"], :name=>"getAttributeKey", :returns=>"javax.swing.text.html.HTML.Attribute"}],
		:origin=>"tests/recursive/javax/swing/text/html/HTML.html",
		:name=>"HTML",
		:package=>"javax.swing.text.html"}
		
		assert( html == res[ 'javax.swing.text.html.HTML' ] )
	end
end

