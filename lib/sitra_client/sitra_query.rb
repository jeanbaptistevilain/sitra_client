class SitraQuery

  include ActiveModel::Serializers::JSON

  attr_accessor :apiKey, :siteWebExportIdV1, :selectionIds

  def initialize(api_key, site_identifier, selections)
    @apiKey = api_key
    @siteWebExportIdV1 = site_identifier
    @selectionIds = selections
  end

  # methods below are implemented manually as they are only available in AR modules which will not be included here

  def attributes=(hash)
    hash.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def attributes
    instance_values
  end

  def to_params
    as_json(:root => false).to_json
  end

end
