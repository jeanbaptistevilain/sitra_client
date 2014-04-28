require 'sitra_client/attribute_helper'
require 'json'

class SitraQuery

  include AttributeHelper

  def initialize(api_key, site_identifier, criteria = {})
    @apiKey = api_key
    @siteWebExportIdV1 = site_identifier
    self.attributes = criteria
  end

  def to_params
    JSON.generate attributes
  end

end
