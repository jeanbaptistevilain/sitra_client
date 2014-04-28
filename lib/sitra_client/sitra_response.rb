require 'sitra_client/attribute_helper'
require 'json'

class SitraResponse

  include AttributeHelper

  def initialize
    @json_response = ''
  end

  def append_line(line)
    @json_response += line unless line.nil?
  end

  def as_hash
    JSON.parse @json_response, :symbolize_names => true
  end

  def as_raw_json
    @json_response
  end

end