require 'sitra_client/attribute_helper'
require 'sitra_client/touristic_object'
require 'json'

class SitraResponse

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

  def as_array
    response = as_hash
    if response[:objetsTouristiques].nil?
      results = []
    else
      results = response[:objetsTouristiques].collect {|obj_hash| TouristicObject.new(obj_hash)}
    end
    results
  end

end