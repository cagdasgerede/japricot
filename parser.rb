class Parser
	def self.prepare file
		doc = File.open(file, "rb") do |file| file.read end
                doc.gsub!( '&nbsp;', ' ' )
                Hpricot( doc )
	end

        def self.parse doc, method
                doc.search('//a[@name]') { |e| 
			get_method_name_and_params( e['name'], method ) 
			#e nin next.next siblingine nasil gidilir?
			pre_node = e.following_siblings[ 1 ]
			get_return_type( pre_node, method )
			get_method_type( pre_node, method )
		}
        end

        def self.get_method_name_and_params( text, method )
                #"format(java.util.Locale, java.lang.String, java.lang.Object...)"
                tmp = text.gsub(/\(/,',').gsub(/\)/,"").gsub(/ /,'').split(/,/)
                method[:name] = tmp.shift
                method[:params] = tmp
        end

	def self.get_return_type pre_node, method
		tmp = pre_node.at('b').preceding_siblings.first
		unless tmp.nil?
			package = tmp['title'].split(/ /).last
			name = tmp.inner_html
			method[:returns]= "#{package}.#{name}"
		else
			tmp2 = pre_node.inner_html.split(' ')
			if tmp2[1] == 'static'
				method[:returns]=tmp2[2]
			else
				method[:returns]=tmp2[1]
			end
		end
	end

	def self.get_method_type pre_node, method
		tmp2 = pre_node.inner_html.split(' ')
		method[:type]='static' if tmp2[1] == 'static'
	end
end
