require "test/unit"
require 'rubygems'
require 'hpricot'
require './folder_parser'

class TestFolderParser < Test::Unit::TestCase
  def test_parse_file_HTML
    key, value = FolderParser.parse_file(File.join('tests','classes','HTML.html')).shift
    assert_equal( 'HTML', value[:class], "Class name mismatch" )
    assert_equal( 'javax.swing.text.html', value[:package], "Package name mismatch" )
    assert_equal( File.join('tests','classes','HTML.html'), value[:origin], "Origin file mismatch" )
    assert_equal( 6, value[:methods].length, "Number of methods mismatch" )
  end
  
  #def test_parse_file_
end

