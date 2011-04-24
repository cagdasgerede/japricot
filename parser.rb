class Parser
	def self.prepare file, params={:fixup_tags=>true}
		doc = File.open(file, "rb") do |file| file.read end
                doc.gsub!( '&nbsp;', ' ' )	
		doc.gsub!( '<p>', '') #problematic <p>'s
		doc.gsub!( '</p>', '') #problematic </p>'s
                Hpricot( doc, params )
	end

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

        def self.parse_single doc, method
                doc.search('//a[@name]') { |e| 
			_parse_method e, method
		}
        end

	def self._parse_method element, method
		get_method_name_and_params( element['name'], method ) 
		pre_node = element.following_siblings[ 1 ]

		#template use in parameters
		tmp = pre_node.inner_html
		unless tmp.match('extends').nil? and tmp.match('super').nil?
			puts "WARNING: Use of templates in parameters not supported yet.
			\nmethod:#{method[:name]}\ncontent:#{tmp}" 
		end

		get_return_type( pre_node, method )
		get_method_type( pre_node, method )
	end

        def self.get_method_name_and_params( text, method )
                #"format(java.util.Locale, java.lang.String, java.lang.Object...)"
                tmp = text.gsub(/\(/,',').gsub(/\)/,"").gsub(/ /,'').split(/,/)
                method[:name] = tmp.shift
                method[:params] = tmp
        end

	def self.get_return_type pre_node, method
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

	def self.get_method_type pre_node, method
		tmp2 = pre_node.inner_html.split(' ')
		method[:type]='static' if tmp2[0] == 'static' or (tmp2[0] == 'public' and tmp2[1] == 'static')
	end
end
