require 'sitra_client/attribute_helper'
require 'sitra_client/touristic_object'
require 'json'

class SitraResponse

  def initialize
    @json_response = ''
    @response_hash = {}
  end

  def append_line(line)
    @json_response += line unless line.nil?
  end

  def returned_count
    [as_hash[:query][:count], results_count - as_hash[:query][:first]].min
  end

  def results_count
    as_hash[:numFound]
  end

  def as_hash
    if @response_hash.empty?
      @response_hash = JSON.parse @json_response, :symbolize_names => true
    end
    @response_hash
  end

  def as_raw_json
    @json_response
  end

  def as_array
    if as_hash[:objetsTouristiques].nil?
      results = []
    else
      results = as_hash[:objetsTouristiques].collect {|obj_hash| TouristicObject.new(obj_hash)}
    end
    results
  end

end