require 'logger'
require 'folder_parser.rb'
$logger = Logger.new STDOUT
$logger.level = Logger::ERROR
$IGNORE_ERROR = true 

folder = '/Users/cagdasgerede/projects/ruby/biter-javadoc-files/docs/api/java/util/zip'
#file = '/Users/cagdasgerede/projects/ruby/biter-javadoc-files/docs/api/java/util/zip/Checksum.html'

#'/Users/cagdasgerede/projects/ruby/biter-javadoc-files/docs/api/

TMP = 'tmp'
Dir.mkdir( TMP ) unless File.directory?( TMP )

parse_output_file = File.join( TMP, "jdk.yaml" ) 

if true
	result = FolderParser.parse_folder "#{folder}" #ARGV[ 0 ]
	#result = FolderParser.parse_file "#{file}" #ARGV[ 0 ]
	File.open( parse_output_file, "w" ) { |file| file.puts( result.to_yaml ) }
end

require 'Jdsl.rb'
db_file = File.join( TMP, "jdk.db" )
File.delete db_file if File.exists? db_file
JDSL.setup db_file, parse_output_file


	