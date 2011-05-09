def _assert expected, method
		assert_equal( expected[:method], method[:name], 'method name' )
		assert_equal( expected[:params], method[:params], "method:#{method[:name]} - parameters:" )
		assert_equal( expected[:returns], method[:returns], "method:#{method[:name]} - return type:" )
		assert_equal( expected[:type], method[:type], "method:#{method[:name]} - type:" )
end