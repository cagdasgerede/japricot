# Run this to see the output of implemented methods.
# This produces 4 yaml files under tmp directory. 
# You can examine these files to understand what is produced.
require 'logger'
require 'folder_parser.rb'
$logger = Logger.new STDOUT
$logger.level = Logger::ERROR
$IGNORE_ERROR = true 

def save file_name, result
	File.open( file_name, "w" ) {|file| file.puts(result.to_yaml) }
end

@file = FolderParser.parse_file File.join('tests','classes','HTML.html')

@files = FolderParser.parse_files [File.join('tests','classes','HTML.html'), File.join('tests','classes','AbstractView.html')]

@folder = FolderParser.parse_folder File.join('tests','folders','1', 'classes')

@folder_all = FolderParser.parse_recursively File.join('tests', 'classes')

TMP = 'tmp'
Dir.mkdir( TMP ) unless File.directory?( TMP )
save File.join(TMP, 'file.yaml'), @file 
save File.join(TMP, 'files.yaml'), @files
save File.join(TMP, 'folder.yaml'), @folder
save File.join(TMP, 'folder_all.yaml'), @folder_all

#x = YAML.load_file 'result.yml'

