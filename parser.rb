# a method consists of 3 parts
# 1) signature: method_name(param_name:type...)
# 2) return_type: void, primite_type, non-primitive_type (Note: non-primitive_type can get complicated
# due to use of arrays and templates which are currently not fully supported).
# 3) "type"(?): static or not.
# 4) access modifier: public, protected, default (not supported).
#
# To extract methods of a class:
# a) call Parser.prepare(file) which returns an Hpricot object;
# b) call Parser.parse_class with Hpricot object returned above. This returns an array
# of methods.
#
# A)
# require './parser.rb'
# doc = Parser.prepare(tests/classes/HTML.html)
# res = Parser.parse_class(doc)
# res.each_with_index do |h,i| puts "#{i}:#{h[:returns]}"
#
# The code produce the following:
# 0:javax.swing.text.html.HTML.Tag[]
# 1:javax.swing.text.html.HTML.Tag
# 2:int
# 3:javax.swing.text.html.HTML.Attribute[]
# 4:void
# 5:javax.swing.text.html.HTML.Attribute
#
#
# B)
# res[1] produces:
#
# {:name=>"getIntegerAttributeValue",
# :params=>["javax.swing.text.AttributeSet", "javax.swing.text.html.HTML.Attribute", "int"],
# :returns=>"int",
# :type=>"static"}
#
#
# c)
# res.each_with_index do |h,i| puts "#{i}:#{h[:returns]}"
#
# This produces:
#
# 0:[]
# 1:["java.lang.String"]
# 2:["javax.swing.text.AttributeSet", "javax.swing.text.html.HTML.Attribute", "int"]
# 3:[]
# 4:["byte[]"]
# 5:["java.lang.String"].

require 'rubygems'
require 'hpricot'

class Parser
  #invoke this to prepare the file to be parsed.
	def self.prepare file, params={:fixup_tags=>true}
		doc = File.open(file, "rb") do |file| file.read end
		doc.gsub!( '&nbsp;', ' ' )
		doc.gsub!( '<p>', '') #problematic <p>'s
		doc.gsub!( '</p>', '') #problematic </p>'s
		Hpricot( doc, params )
	end

  #invoke this to parse a single class to get methods in the class.
	def self.parse_class doc
		methods = []
		anchor = doc.at('//a[@name=method_detail]')
		unless anchor.nil?
			anchor.following_siblings.each { |e| 
				if e.name='a' and 
					not e['name'].nil? and 
					e['name']!='navbar_bottom' and 
					e['name']!='skip-navbar_bottom'		
	
					method = {}
					_parse_method( e, method )
					methods.push method
				end
			}
		#else (no method exists)
		end
		methods
	end

	def self._parse_method element, method
		extract_method_name_and_params( element['name'], method )
		pre_node = element.following_siblings[ 1 ]

		#template use in parameters
		tmp = pre_node.inner_html
		unless tmp.match('extends').nil? and tmp.match('super').nil?
			puts "WARNING: Use of templates in parameters not supported yet.
			\nmethod:#{method[:name]}\ncontent:#{tmp}" 
		end

		extract_return_type( pre_node, method )
		extract_method_type( pre_node, method )
	end

	#auxilary method created during test creation
	def self.parse_single doc, method
		doc.search('//a[@name]') { |e|
			_parse_method e, method
		}
  end

  private

  #extract signature
  def self.extract_method_name_and_params( text, method )
    #"format(java.util.Locale, java.lang.String, java.lang.Object...)"
    tmp = text.gsub(/\(/,',').gsub(/\)/,"").gsub(/ /,'').split(/,/)
    method[:name] = tmp.shift
    method[:params] = tmp
  end

	#extracts return type (e.g., void, int, LinkedList, String[]).
	def self.extract_return_type pre_node, method
		pre_node_siblings = pre_node.at('b').preceding_siblings
		tmp = pre_node_siblings.first

		# mainly because we have to deal with [] use. Current detection of [] assumes no template use.
		puts "WARNING: Template uses in return type not supported yet. \nmethod: #{method[:name]}\ncontent: #{pre_node_siblings}" if pre_node_siblings.size > 1

		unless tmp.nil? #go here when non-primitive type (e.g., public static <a href=...String...)
			package = tmp['title'].split(/ /).last
			name = tmp.inner_html
			method[:returns]= "#{package}.#{name}"
			method[:returns] << '[]'  if pre_node.at('b').previous.to_s.strip == "[]" # array of objects
		else #go here when primitive type (e.g., public static int)
			tmp2 = pre_node.inner_html.split(' ')
			if tmp2[0] == 'public' or tmp2[0] == 'protected' #sometimes there is public/protected 	
				if tmp2[1] == 'static'
					return_index = 2
				else
					return_index = 1 
				end
			else #sometimes there is no public/protected
				if tmp2[0] == 'static'
					return_index = 1
				else	
					return_index = 0
				end
			end

			method[:returns] = tmp2[return_index]
		end
	end

	#method type can be static or none.
	def self.extract_method_type pre_node, method
		tmp2 = pre_node.inner_html.split(' ')    
		method[:type]='static' if tmp2[0] == 'static' or (tmp2[0] == 'public' and tmp2[1] == 'static')
	end
end
