# encoding: UTF-8
require 'sitra_client/attribute_helper'

class TouristicObject

  include AttributeHelper

  SPECIFIC_INFOS = {
    'ACTIVITE' => '@informationsActivite',
    'COMMERCE_ET_SERVICE' => '@informationsCommerceEtService',
    'DEGUSTATION' => '@informationsDegustation',
    'DOMAINE_SKIABLE' => '@informationsDomaineSkiable',
    'EQUIPEMENT' => '@informationsEquipement',
    'FETE_ET_MANIFESTATION' => '@informationsFeteEtManifestation',
    'HEBERGEMENT_COLLECTIF' => '@informationsHebergementCollectif',
    'HEBERGEMENT_LOCATIF' => '@informationsHebergementLocatif',
    'HOTELLERIE' => '@informationsHotellerie',
    'HOTELLERIE_PLEIN_AIR' => '@informationsHotelleriePleinAir',
    'PATRIMOINE_CULTUREL' => '@informationsPatrimoineCulturel',
    'PATRIMOINE_NATUREL' => '@informationsPatrimoineNaturel',
    'RESTAURATION' => '@informationsRestauration',
    'SEJOUR_PACKAGE' => '@informationsSejourPackage',
    'STRUCTURE' => '@informationsStructure',
    'TERRITOIRE' => '@informationsTerritoire'
  }

  DEFAULT_LIBELLE = :libelleFr

  PHONE = 201
  EMAIL = 204
  WEBSITE = 205

  def initialize(hash)
    self.attributes = hash
    @libelle = DEFAULT_LIBELLE
  end

  def set_locale(locale)
    unless locale.nil?
      @libelle = "libelle#{locale.capitalize}".to_sym
    end
  end

  def id
    @id.to_s
  end

  def type
    @type
  end

  def title
    @nom[@libelle] || @nom[DEFAULT_LIBELLE]
  end

  def description
    if @presentation[:descriptifCourt]
      @presentation[:descriptifCourt][@libelle] || @presentation[:descriptifCourt][DEFAULT_LIBELLE]
    end
  end

  def details
    if @presentation[:descriptifDetaille]
      @presentation[:descriptifDetaille][@libelle] || @presentation[:descriptifDetaille][DEFAULT_LIBELLE]
    end
  end

  def contact(types_ids = [])
    contact_details = {}
    contact_entries = @informations[:moyensCommunication].nil? ? [] : @informations[:moyensCommunication]
    contact_entries.each do |c|
      if types_ids.include?(c[:type][:id])
        label = c[:type][@libelle]
        contact_details[label] = c[:coordonnee]
      end
    end
    contact_details
  end

  def information
    specific_information = {}
    unless @type.nil?
      specific_information = instance_variable_get(SPECIFIC_INFOS[@type])
    end
    @informations.merge(specific_information)
  end

  def picture_url(default_url)
    @imagePrincipale.nil? ? default_url : @imagePrincipale[:traductionFichiers][0][:url]
  end

  def service_provider
    if @informationsActivite && @informationsActivite[:commerceEtServicePrestataire]
      @informationsActivite[:commerceEtServicePrestataire][:nom][@libelle]
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
    computed_address = ''
    computed_address += "#{address_details[:adresse1]}, " unless address_details[:adresse1].nil?
    computed_address + address_details[:commune][:nom]
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
      @ouverture[:periodeEnClair][@libelle]
    end
  end

  def tarif
    if @descriptionTarif
      if @descriptionTarif[:gratuit]
        return 'gratuit'
      elsif @descriptionTarif[:tarifsEnClair]
        @descriptionTarif[:tarifsEnClair][@libelle]
      end
    end
  end

  def population
    eligible_populations = []
    if @prestations && @prestations[:typesClientele]
      eligible_populations += @prestations[:typesClientele].collect {|t| t[@libelle]}
    end
    eligible_populations.uniq
  end

  def prestations(prestation_type)
    @prestations && @prestations[prestation_type] && @prestations[prestation_type].collect {|t| t[@libelle]}
  end

  def environments
    @localisation && @localisation[:environnements] && @localisation[:environnements].collect {|e| e[@libelle]}
  end

  def additional_criteria
    @presentation && @presentation[:typologiesPromoSitra] && @presentation[:typologiesPromoSitra].collect {|t| t[@libelle]}
  end

  def resa
    if @reservation
      @reservation[:organismes]
    end
  end

  def pdf_link
    @multimedias
  end

  def reservation
    if @reservation[:complement]
      @reservation[:complement][:libelleFr] || @reservation[:complement][DEFAULT_LIBELLE]
    end
  end

  def bonplan
    if @presentation[:bonsPlans]
      @presentation[:bonsPlans][@libelle] || @presentation[:bonsPlans][DEFAULT_LIBELLE]
    end
  end

  def cpltaccueil
    @prestations && @prestations[:complementAccueil] && @prestations[:complementAccueil][:libelleFr]
  end

  def accessibilite
    @prestations && @prestations[:tourismesAdaptes] && @prestations[:tourismesAdaptes].collect {|t| t[@libelle]}
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