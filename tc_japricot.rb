require "test/unit"
require 'rubygems'
require 'hpricot'
require './parser'
require 'logger'

$logger = Logger.new(STDOUT)
#$logger = Logger.new('logfile.log')
$logger.level = Logger::ERROR

require './tests/test_parser_methods'
require './tests/test_parser_classes'
require './tests/test_folder_parser'
require './tests/test_db_manager'
