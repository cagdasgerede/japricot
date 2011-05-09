require 'rubygems'
require 'hpricot'
require './parser'

class FolderParser

  def x
    path = 'tests\classes\HTML.html'
    expected_class_name = path.split('\\').last.split('.').first

    doc = Parser.prepare 'tests\classes\HTML.html'
    res = doc.search("//meta[@content]~= 'class'")

    #bu bekledigimiz gibi bir klas.
    unless res.nil?
      pkg_class = res.first[:content].split[0] #javax.swing.text.html.HTML
      raise Exception.new "" if expected_class_name != pkg_class.split('.').pop
    end

  end
end