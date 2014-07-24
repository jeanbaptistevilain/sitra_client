require 'sitra_client/version'
require 'sitra_client/sitra_query'
require 'sitra_client/sitra_response'
require 'open-uri'
require 'logger'

module SitraClient

  DEFAULT_COUNT = 50

  # Configuration defaults
  @config = {
      :base_url => 'http://api.sitra-tourisme.com/api/v001',
      :api_key => '',
      :site_identifier => '',
      :results_count => DEFAULT_COUNT
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

  def self.query(criteria = {})
    response = SitraResponse.new
    unless criteria.has_key?(:count)
      criteria[:count] = @config[:results_count]
    end
    query = SitraQuery.new(@config[:api_key], @config[:site_identifier], criteria)
    @logger.info "Search query : #{@config[:base_url]}/recherche/list-objets-touristiques?query=#{query.to_params}"
    open("#{@config[:base_url]}/recherche/list-objets-touristiques?query=#{CGI.escape query.to_params}") { |f|
      f.each_line {|line| response.append_line(line)}
    }
    response
  end

end
