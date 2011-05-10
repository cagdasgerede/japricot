require 'rubygems'
require 'hpricot'
require './parser'


class FolderParser

  def self.parse_folder folder='tests\classes'
    entries = Dir.new( folder ).entries
    html_files = entries.select do |e|
      e.match( /^\./ ).nil? and 
        not File.directory? e and
        e.match( /.html$/ )
    end
    
    html_files.map! do |f|
      "#{folder}\\#{f}"      
    end
    pp html_files
    #pp parse_files html_files
    #pp parse_files [ "tests\\classes\\AbstractView.html"]
    #pp parse_files [ "tests\\classes\\AlertListener.html"]    
  end

  def self.parse_files paths= [ 'tests\classes\HTML.html', 'tests\classes\BitVector.html', 'tests\classes\ZipFile.html' ]
    result = {}
    paths.each do |path|
      extracted = parse_file( path )
      pkg_and_class = extracted.keys.first
      unless result[ pkg_and_class ].nil?
        $logger.error "The class #{pkg_and_class} already extracted in the file #{result[pkg_and_class][:origin]} is tried to be extracted again in the file #{path}"
      else
        result.merge!( extracted )
      end
    end
    result
  end
  
  def self.parse_file path= 'tests\classes\HTML.html'

    expected_class = path.split('\\').last.split('.').first
    doc = Parser.prepare path
    res = doc.search("//meta[@content ~= 'class']")#<meta name="keywords" content="javax.swing.text.html.HTML class">
    
    unless res.nil?      
      pkg_and_class = res.first[:content].split[0] #javax.swing.text.html.HTML
      tmp = pkg_and_class.split( '.' )
      klass = tmp.pop
      pkg = tmp.join( '.' )

      if expected_class != klass
        msg = "Expected class name #{expected_class} do not match with the class name #{klass} in the file #{path}"
        $logger.fatal( msg )
        raise Exception.new msg
      end
      methods = Parser.parse_class( Parser.prepare( path ) )
      return { pkg_and_class => {:class => klass, :package => pkg, :origin => path, :methods => methods} }
    else
      $logger.warn "This (#{path}) is not a class. Skipping."
      return {}
    end
  end
end



