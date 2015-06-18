require 'rubygems'
gem 'shoulda'
require 'test/unit'
require 'shoulda'
require 'sitra_client/sitra_query'

class SitraQueryTest < Test::Unit::TestCase

  should 'populate query with parameters' do

    query = SitraQuery.new('dummy_key', 'dummy_identifier', {:first_key => 'first_value', :second_key => 'second_value'})

    assert_equal '{"apiKey":"dummy_key","projetId":"dummy_identifier","first_key":"first_value","second_key":"second_value"}', query.to_params
  end

end