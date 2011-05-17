require 'rubygems'
require 'hpricot'
require './parser'


class FolderParser

  def self.parse_folder folder = File.join('tests', 'classes')
    entries = Dir.new( folder ).entries
    html_files = entries.select do |e|
      e.match( /^\./ ).nil? and 
        not File.directory? e and
        e.match( /.html$/ )
    end
    
    html_files.map! do |f|
      File.join( folder, f )      
    end
	
	$logger.info html_files
	res = parse_files html_files
	$logger.info res
	res
  end

	# accepts an arroy of file paths,
	# returns a hash of hashes of extracted information
  def self.parse_files paths#=[File.join('tests','classes','HTML.html'), File.join('tests','classes','BitVector.html'),File.join('tests','classes','ZipFile.html') ]
    result = {}
    paths.each do |path|
      extracted = parse_file( path )
      pkg_and_name = extracted.keys.first
      unless result[ pkg_and_name ].nil?
        $logger.error "The class #{pkg_and_name} already extracted in the file #{result[pkg_and_name][:origin]} is tried to be extracted again in the file #{path}"
      else
        result.merge!( extracted )
      end
    end
    result
  end
  
  # FolderParser.parse_file(File.join('tests','classes','HTML.html'))
	# produces a hash as follows:
  # {"javax.swing.text.html.HTML"=>
	#		{ :name =>"HTML", :package=>"javax.swing.text.html",
	#			:type =>:class, :origin=>"tests/classes/HTML.html",
	#			:methods=> ... } }
	#	
	# type can be interface or class. Key of the hash shows the full package path of the file
	def self.parse_file path#= File.join('tests','classes','HTML.html')
		expected_name = path.split( File::SEPARATOR ).last.split('.').first
    doc = Parser.prepare path
    res = doc.search("//meta[@content *= ' class']")#<meta name="keywords" content="javax.swing.text.html.HTML class">
	if res.first.nil?
		res = doc.search("//meta[@content *= ' interface']")
		if res.first.nil?
			type = :unknown
		else
			type = :interface
		end
	else
		type = :class
	end

	if type == :class || type == :interface      
      pkg_and_name = res.first[:content].split[0] #javax.swing.text.html.HTML
      tmp = pkg_and_name.split( '.' )
      name = tmp.pop
      pkg = tmp.join( '.' )

      if expected_name != name
        msg = "Expected class/interface name #{expected_name} do not match with the class/interface name #{name} in the file #{path}"
        $logger.fatal( msg )
        raise Exception.new( msg )
      end
      methods = Parser.parse_class( Parser.prepare( path ) )
      return { pkg_and_name => {:name => name, :package => pkg, :type => type, 
		:origin => path, :methods => methods } }
    else
      $logger.warn "This (#{path}) is not a class/interface. Skipping."
      return {}
    end
  end
end



