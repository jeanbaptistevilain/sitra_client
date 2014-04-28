require 'rubygems'
gem 'shoulda'
require 'test/unit'
require 'shoulda'
require 'sitra_client/sitra_response'


class SitraResponseTest < Test::Unit::TestCase

  setup do
    @response = '{"apiKey":"dummy_key","siteWebExportIdV1":"dummy_identifier","first_key":"first_value","second_key":"second_value"}'
  end

  should 'store raw json response' do

    sitra_response = SitraResponse.new
    sitra_response.append_line(@response)

    assert_equal @response, sitra_response.as_raw_json

  end

  should 'return response as hash' do

    sitra_response = SitraResponse.new
    sitra_response.append_line(@response)

    response_hash = sitra_response.as_hash

    assert_equal 'dummy_key',  response_hash[:apiKey]
    assert_equal 'dummy_identifier',  response_hash[:siteWebExportIdV1]
    assert_equal 'first_value',  response_hash[:first_key]
    assert_equal 'second_value',  response_hash[:second_key]

  end

end