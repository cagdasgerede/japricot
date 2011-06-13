require 'logger'
require 'folder_parser.rb'
$logger = Logger.new STDOUT
$logger.level = Logger::ERROR
$IGNORE_ERROR = true 

folder = '/Users/cagdasgerede/projects/ruby/biter-javadoc-files/docs/api/java/util/zip'
#file = '/Users/cagdasgerede/projects/ruby/biter-javadoc-files/docs/api/java/util/zip/CRC32.html'

#'/Users/cagdasgerede/projects/ruby/biter-javadoc-files/docs/api/

TMP = 'tmp'


parse_output_file = File.join( TMP, "jdk.yaml" ) 
#file_name = File.join( TMP, "#{ARGV[1]}.yaml" ) 

if true
	parse_output = YAML.load_file parse_output_file
else
	result = FolderParser.parse_folder "#{folder}" #ARGV[ 0 ]
	#result = FolderParser.parse_file "#{file}" #ARGV[ 0 ]
	#puts result.to_yaml


	Dir.mkdir( TMP ) unless File.directory?( TMP )
	File.open( parse_output_file, "w" ) { |file| file.puts( result.to_yaml ) }
end

require 'Jdsl.rb'
db_file = File.join( TMP, "jdk.db" )
File.delete db_file if File.exists? db_file
JDSL.setup db_file, parse_output_file

#'String'.jclass.print
#''.allcandidates.sort.print

	