# encoding: UTF-8
require 'sitra_client/attribute_helper'

class TouristicObject

  include AttributeHelper

  def initialize(hash)
    self.attributes = hash
  end

  def id
    @id.to_s
  end

  def title
    @nom[:libelleFr]
  end

  def description
    @presentation[:descriptifCourt][:libelleFr] unless @presentation[:descriptifCourt].nil?
  end

  def details
    @presentation[:descriptifDetaille][:libelleFr] unless @presentation[:descriptifDetaille].nil?
  end

  def contact
    contact_details = {}
    contact_entries = @informations[:moyensCommunication].nil? ? [] : @informations[:moyensCommunication]
    contact_entries.each do |c|
      label = c[:type][:libelleFr]
      contact_details[c[:type][:libelleFr]] = c[:coordonnee] unless label == 'Fax'
    end
    contact_details
  end

  def picture_url(default_url)
    @imagePrincipale.nil? ? default_url : @imagePrincipale[:traductionFichiers][0][:url]
  end

  def service_provider
    if @informationsActivite && @informationsActivite[:commerceEtServicePrestataire]
      @informationsActivite[:commerceEtServicePrestataire][:nom][:libelleFr]
    elsif @informationsFeteEtManifestation
      @informationsFeteEtManifestation[:nomLieu]
    else
      nil
    end
  end

  def address_details
    if @informationsActivite && @informationsActivite[:commerceEtServicePrestataire]
      @informationsActivite[:commerceEtServicePrestataire][:adresse]
    else
      @localisation[:adresse]
    end
  end

  def address
    "#{address_details[:adresse1]}, #{address_details[:commune][:nom]}"
  end

  def latitude
    geoloc_details = parse_geoloc_details
    geoloc_details[:valide] ? geoloc_details[:geoJson][:coordinates][1] : nil
  end

  def longitude
    geoloc_details = parse_geoloc_details
    geoloc_details[:valide] ? geoloc_details[:geoJson][:coordinates][0] : nil
  end

  def horaires
    if @ouverture && @ouverture[:periodeEnClair]
      @ouverture[:periodeEnClair][:libelleFr]
    end
  end

  def tarif
    if @descriptionTarif
      if @descriptionTarif[:gratuit]
        return 'gratuit'
      elsif @descriptionTarif[:tarifsEnClair]
        @descriptionTarif[:tarifsEnClair][:libelleFr]
      end
    end
  end

  def population
    eligible_populations = []
    if @prestations && @prestations[:typesClientele]
      eligible_populations += @prestations[:typesClientele].collect {|t| t[:libelleFr]}
    end
    eligible_populations.uniq
  end

  def adapted_tourism
    @prestations && @prestations[:tourismesAdaptes] && @prestations[:tourismesAdaptes].collect {|t| t[:libelleFr]}
  end

  def environments
    @localisation && @localisation[:environnements] && @localisation[:environnements].collect {|e| e[:libelleFr]}
  end

  def additional_criteria
    @presentation && @presentation[:typologiesPromoSitra] && @presentation[:typologiesPromoSitra].collect {|t| t[:libelleFr]}
  end

  private

  def parse_geoloc_details
    if @informationsActivite.nil? || @informationsActivite[:commerceEtServicePrestataire].nil?
      geoloc_details = @localisation[:geolocalisation]
    else
      geoloc_details = @informationsActivite[:commerceEtServicePrestataire][:geolocalisation]
    end
    geoloc_details
  end

end