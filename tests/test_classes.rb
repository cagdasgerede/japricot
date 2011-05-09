require "test/unit"
require 'rubygems'
require 'hpricot'
require './parser'
require './tests/test_helper'

class TestClasses < Test::Unit::TestCase

  CLASS_TEST_FOLDER = 'tests/classes'

  def _test_class config
		doc = Parser.prepare config[:file]
		methods = Parser.parse_class( doc )
		assert_equal( config[:methods].size, methods.size, "Number of methods do not match" )
		methods.each_with_index do |e,i|
			expected = config[:methods][i]
			#puts "testdef: #{expected[:method]} --- parsed: #{e[:name]}"
			_assert expected, e
		end
	end
  
	def test_ZipFile
		config = {:file => "#{CLASS_TEST_FOLDER}/ZipFile.html",
			:methods=>[
				{:method=> 'getEntry',
				:params=> ['java.lang.String'],
				:returns=>'java.util.zip.ZipEntry',
				:type => nil
				},
				{:method=> 'getInputStream',
				:params=> ['java.util.zip.ZipEntry'],
				:returns=>'java.io.InputStream',
				:type => nil
				},
				{:method=> 'getName',
				:params=> [],
				:returns=>'java.lang.String',
				:type => nil
				},
				{:method=> 'entries',
				:params=> [],
				:returns=>'java.util.Enumeration', #::java.util.zip.ZipEntry',
				:type => nil
				},
				{:method=> 'drainTo',
				:params=> ['java.util.Collection'],
				:returns=>'int',
				:type => nil
				},
				{:method=> 'size',
				:params=> [],
				:returns=>'int',
				:type => nil
				},
				{:method=> 'close',
				:params=> [],
				:returns=>'void',
				:type => nil
				},
				{:method=> 'finalize',
				:params=> [],
				:returns=>'void',
				:type => nil
				},
			]}
		_test_class config
	end

	def test_HTML
		config = {:file => "#{CLASS_TEST_FOLDER}/HTML.html",
			:methods=>[
				{:method=> 'getAllTags',
				:params=> [],
				:returns=>'javax.swing.text.html.HTML.Tag[]',
				:type => 'static'
				},
				{:method=> 'getTag',
				:params=> [ 'java.lang.String'],
				:returns=> 'javax.swing.text.html.HTML.Tag',
				:type => 'static'
				},
				{:method=> 'getIntegerAttributeValue',
				:params=> ['javax.swing.text.AttributeSet', 'javax.swing.text.html.HTML.Attribute', 'int' ],
				:returns=> 'int',
				:type => 'static'
				},
				{:method=> 'getAllAttributeKeys',
				:params=> [],
				:returns=>'javax.swing.text.html.HTML.Attribute[]',
				:type => 'static'
				},
				{:method=> 'setExtra',
				:params=> [ 'byte[]'],
				:returns=>'void',
				:type => nil
				},
				{:method=> 'getAttributeKey',
				:params=> [ 'java.lang.String'],
				:returns=>'javax.swing.text.html.HTML.Attribute',
				:type => 'static'
				},
			]}
		_test_class config
	end

	def test_BitVector
		config = {:file => "#{CLASS_TEST_FOLDER}/BitVector.html",
			:methods=>[
				{:method=> 'at',
				:params=> ['int'],
				:returns=>'int',
				:type => nil
				},
				{:method=> 'size',
				:params=> [],
				:returns=>'int',
				:type => nil
				},
				{:method=> 'sizeInBytes',
				:params=> [],
				:returns=>'int',
				:type => nil
				},
				{:method=> 'appendBit',
				:params=> [ 'int'],
				:returns=>'void',
				:type => nil
				},
				{:method=> 'appendBits',
				:params=> [ 'int', 'int'],
				:returns=>'void',
				:type => nil
				},
				{:method=> 'appendBitVector',
				:params=> [ 'com.google.zxing.qrcode.encoder.BitVector'],
				:returns=>'void',
				:type => nil
				},
				{:method=> 'xor',
				:params=> [ 'com.google.zxing.qrcode.encoder.BitVector'],
				:returns=>'void',
				:type => nil
				},
				{:method=> 'toString',
				:params=> [],
				:returns=>'java.lang.String',
				:type => nil
				},
				{:method=> 'getArray',
				:params=> [],
				:returns=>'byte[]',
				:type => nil
				}
			]}
		_test_class config
	end

	def test_BarcodeDecoder
		config = {:file => "#{CLASS_TEST_FOLDER}/BarcodeDecoder.html",
			:methods=>[
			]}
		_test_class config
	end

	def test_AlertListener
		config = {:file => "#{CLASS_TEST_FOLDER}/AlertListener.html",
			:methods=>[
				{:method=> 'audioDone',
				:params=> ['int'],
				:returns=>'void',
				:type => nil
				},
				{:method=> 'buzzerDone',
				:params=> ['int'],
				:returns=>'void',
				:type => nil
				},
				{:method=> 'vibrateDone',
				:params=> ['int'],
				:returns=>'void',
				:type => nil
				}
			]}
		_test_class config
	end

	def test_AccelerometerSensor
		config = {:file => "#{CLASS_TEST_FOLDER}/AccelerometerSensor.html",
			:methods=>[
				{:method=> 'isSupported',
				:params=> [],
				:returns=>'boolean',
				:type => 'static'
				},
				{:method=> 'openOrientationDataChannel',
				:params=> ['net.rim.device.api.system.Application'],
				:returns=>'net.rim.device.api.system.AccelerometerSensor.Channel',
				:type => 'static'
				},
				{:method=> 'openRawDataChannel',
				:params=> ['net.rim.device.api.system.Application'],
				:returns=>'net.rim.device.api.system.AccelerometerSensor.Channel',
				:type => 'static'
				},
				{:method=> 'openChannel',
				:params=> ['net.rim.device.api.system.Application',
					'net.rim.device.api.system.AccelerometerChannelConfig'],
				:returns=>'net.rim.device.api.system.AccelerometerSensor.Channel',
				:type => 'static'
				}
			]}
		_test_class config
	end

	def test_AbstractView
		config = {:file => "#{CLASS_TEST_FOLDER}/AbstractView.html",
			:methods=>[
				{:method=> 'getDocument',
				:params=> [],
				:returns=>'org.w3c.dom.views.DocumentView',
				:type => nil
				}
			]}
		_test_class config
	end
end
