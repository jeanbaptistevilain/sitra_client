require 'sitra_client/version'
require 'sitra_client/sitra_query'
require 'sitra_client/sitra_response'
require 'open-uri'
require 'json'
require 'logger'

module SitraClient

  MAX_COUNT = 100

  # Safety net
  MAX_LOOPS = 5

  # Configuration defaults
  @config = {
      :base_url => 'http://api.sitra-tourisme.com/api/v002',
      :api_key => '',
      :site_identifier => ''
  }

  @valid_config_keys = @config.keys
  @logger = Logger.new(STDOUT)

  # Configure through hash
  def self.configure(opts = {})
    opts.each {|k,v| @config[k.to_sym] = v if @valid_config_keys.include? k.to_sym}
  end

  def self.config
    @config
  end

  def self.query(criteria, all_results = false)
    query_result = {}
    if all_results
      loops = 0
      criteria[:first] = 0
      criteria[:count] = MAX_COUNT
      response = get_response(criteria)
      results = response.as_array
      while response.results_count > results.length && loops < MAX_LOOPS
        loops += 1
        criteria[:first] += MAX_COUNT
        results += get_response(criteria).as_array
      end
      query_result[:count] = response.results_count
      query_result[:results] = results
    else
      response = get_response(criteria)
      results = response.as_array
      query_result[:count] = response.results_count
      query_result[:results] = results
    end
    query_result
  end

  def self.selections
    response = ''
    query = SitraQuery.new(@config[:api_key], @config[:site_identifier])
    @logger.info "Selections retrieval query : #{@config[:base_url]}/referentiel/selections?query=#{query.to_params}"
    open("#{@config[:base_url]}/referentiel/selections?query=#{CGI.escape query.to_params}") { |f|
      f.each_line {|line| response += line if line}
    }
    JSON.parse response, symbolize_names: true
  end

  private

  def self.get_response(criteria)
    response = SitraResponse.new
    query = SitraQuery.new(@config[:api_key], @config[:site_identifier], criteria)
    @logger.info "Search query : #{@config[:base_url]}/recherche/list-objets-touristiques?query=#{query.to_params}"
    open("#{@config[:base_url]}/recherche/list-objets-touristiques?query=#{CGI.escape query.to_params}") { |f|
      f.each_line {|line| response.append_line(line)}
    }
    @logger.info "Retrieved #{response.returned_count} of #{response.results_count} results"
    response
  end

end
