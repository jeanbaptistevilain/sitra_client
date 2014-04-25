require 'sitra_client/version'
require 'sitra_client/sitra_query'
require 'open-uri'

module SitraClient

  # Configuration defaults
  @config = {
      :base_url => 'http://api.sitra-tourisme.com/api/v001',
      :api_key => '',
      :site_identifier => ''
  }

  @valid_config_keys = @config.keys

  # Configure through hash
  def self.configure(opts = {})
    opts.each {|k,v| @config[k.to_sym] = v if @valid_config_keys.include? k.to_sym}
  end

  def self.config
    @config
  end

  def self.query(criteria = {})
    results = []
    query = SitraQuery.new(@config[:api_key], @config[:site_identifier], criteria)
    puts "#{@config[:base_url]}/recherche/list-objets-touristiques?query=#{query.to_params}"
    open("#{@config[:base_url]}/recherche/list-objets-touristiques?query=#{CGI.escape query.to_params}") { |f|
      f.each_line {|line| results << line}
    }
    results
  end

end
