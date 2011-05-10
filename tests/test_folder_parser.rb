require "test/unit"
require 'rubygems'
require 'hpricot'
require './folder_parser'

class TestFolderParser < Test::Unit::TestCase
  def test_parse_file
    key, value = FolderParser.parse_file('tests\classes\HTML.html').first
    assert_equal( 'HTML', value[:class], "Class name mismatch" )
    assert_equal( 'javax.swing.text.html', value[:package], "Package name mismatch" )
    assert_equal( 'tests\classes\HTML.html', value[:origin], "Origin file mismatch" )
    assert_equal( 6, value[:methods].count, "Number of methods mismatch" )
  end
end

