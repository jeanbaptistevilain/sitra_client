# encoding: UTF-8
require 'active_support/duration'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/integer/time'
require 'sitra_client/attribute_helper'

class TouristicObject

  include AttributeHelper

  DEFAULT_LIBELLE = :libelleFr

  ASPECT_WINTER = 'HIVER'
  ASPECT_SUMMER = 'ETE'
  ASPECT_CHALLENGED = 'HANDICAP'
  ASPECT_BUSINESS = 'TOURISME_AFFAIRES'
  ASPECT_GROUPS = 'GROUPES'
  ASPECT_ACTIVITIES = 'PRESTATAIRE_ACTIVITES'

  PHONE = 201
  EMAIL = 204
  WEBSITE = 205

  WEEKDAYS_FR = ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi']

  def initialize(hash, aspect = nil)
    if aspect && hash[:aspects]
      aspect_data = hash[:aspects].select {|a| a[:aspect] == aspect && !a[:champsAspect].blank?}.first
      self.attributes = aspect_data ? aspect_hash(hash, aspect_data) : hash
    else
      self.attributes = hash
    end
    @libelle = DEFAULT_LIBELLE
  end

  def aspect_hash(all_fields, aspect_fields)
    all_data = all_fields.except(:aspects)
    aspect_data = aspect_fields.except(:aspect, :champsAspect)
    overrides = aspect_fields[:champsAspect]
    overrides.each do |o|
      path = o.split('.').map(&:to_sym)
      if all_data.dig(path.first, *path[1..-1]) && aspect_fields.dig(path.first, *path[1..-1]).nil?
        *keys, last_key = path
        keys.inject(all_data, :fetch)[last_key] = nil
      end
    end
    all_data.deep_merge(aspect_data)
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

  def specific_info(capitalize = false)
    type = @type.downcase.split('_')
    type.each_index do |index|
      if index > 0
        type[index] = type[index].capitalize
      end
    end
    if capitalize
      @specific_info = type.join('').capitalize
    else
      @specific_info = type.join('')
    end
  end

  def sub_type
    infos_label = '@informations' + specific_info(true)
    type_label = specific_info + 'Type'

    infos_type = instance_variable_get(infos_label)
    if infos_type && infos_type[type_label.to_sym]
      infos_type[type_label.to_sym][@libelle] || infos_type[type_label.to_sym][DEFAULT_LIBELLE]
    end
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
        contact_details[label] = c[:coordonnees][:fr]
      end
    end
    contact_details
  end

  def information
    specific_information = {}
    unless @type.nil?
      specific_information = instance_variable_get('@informations' + specific_info(true))
    end
    @informations.merge(specific_information)
  end

  def pictures
    (@illustrations.nil? || @illustrations.empty?) ? [{}] :
        @illustrations.collect {|i| i[:traductionFichiers][0].keep_if {|k, v| k.to_s.start_with?('url')}}
  end

  def service_provider
    if @informationsActivite && @informationsActivite[:prestataireActivites]
      @informationsActivite[:prestataireActivites][:nom][@libelle]
    elsif @informationsFeteEtManifestation
      @informationsFeteEtManifestation[:nomLieu]
    else
      nil
    end
  end

  def address_details
    if @informationsActivite && @informationsActivite[:prestataireActivites]
      @informationsActivite[:prestataireActivites][:adresse]
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

  def open_on?(start_date, end_date)
    opening_periods = @ouverture[:periodesOuvertures]
    is_open = false
    unless opening_periods.nil? || opening_periods.empty?
      i = 0
      while !is_open && i < opening_periods.length
        period_start = Date.parse(opening_periods[i][:dateDebut])
        period_end = Date.parse(opening_periods[i][:dateFin])
        start_day = Date.parse(start_date)
        end_day = [Date.parse(end_date), start_day.next_month].min
        if ranges_intersect(period_start, period_end, start_day, end_day, opening_periods[i][:tousLesAns])
          is_open = (start_day..end_day).to_a.any? {|d| open_day_predicate(opening_periods[i]).call(d)}
        end
        i += 1
      end
    end
    is_open
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
    presta = {}
    unless @prestations.nil? || @prestations[prestation_type].nil?
      @prestations[prestation_type].each do |item|
        value = item[@libelle]
        if item[:familleCritere].nil?
          key = 'Autre'
        else
          key = item[:familleCritere][:libelleFr]
        end
        presta[key] ||= []
        presta[key] << value
      end
    end
    presta
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

  def multimedias
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

  def ranges_intersect(ref_start_day, ref_end_day, other_start_day, other_end_day, ignore_year = false)
    has_intersection = other_start_day.between?(ref_start_day, ref_end_day) || other_end_day.between?(ref_start_day, ref_end_day) ||
        ref_start_day.between?(other_start_day, other_end_day) || ref_end_day.between?(other_start_day, other_end_day)
    if !has_intersection && ignore_year && ref_start_day <= other_end_day
      ref_start_day = ref_start_day.next_year
      ref_end_day = ref_end_day.next_year
      has_intersection = ranges_intersect(ref_start_day, ref_end_day, other_start_day, other_end_day, true)
    end
    has_intersection
  end

  def open_day_predicate(opening_period)
    is_eligible = lambda {|date| return true}
    case(opening_period[:type])
      when 'OUVERTURE_SAUF'
        excluded_days = opening_period[:ouverturesJournalieres].collect {|o| WEEKDAYS_FR.index(o[:jour].downcase)}
        is_eligible = lambda {|date| return !excluded_days.include?(date.wday)}
      when 'OUVERTURE_TOUS_LES_JOURS'
      when 'OUVERTURE_SEMAINE'
        unless opening_period[:ouverturesJournalieres][0][:jour] == 'TOUS'
          included_days = opening_period[:ouverturesJournalieres].collect {|o| WEEKDAYS_FR.index(o[:jour].downcase)}
          is_eligible = lambda {|date| return included_days.include?(date.wday)}
        end
      when 'OUVERTURE_MOIS'
        opening_days = {}
        unless opening_period[:ouverturesJourDuMois].nil?
          opening_period[:ouverturesJourDuMois].each {|o| opening_days[o[:jour].downcase] = o[:jourDuMois]}
        end
        if opening_days.keys.include?('tous')
          is_eligible = lambda {|date| return occurrence_in_month(date) == opening_days['tous']}
        else
          included_weekdays = opening_days.keys.collect {|d| WEEKDAYS_FR.index(d)}
          is_eligible = lambda {|date| return included_weekdays.include?(date.wday) && occurrence_in_month(date) == opening_days[WEEKDAYS_FR[date.wday]]}
        end
      else
      # Unsupported
    end
    is_eligible
  end

  def certification
    if @informationsHebergementCollectif && @informationsHebergementCollectif[:labels]
      @informationsHebergementCollectif[:labels].collect {|t| t[:id]}
    else
      @informationsHebergementLocatif[:labels].collect {|t| t[:id]}
    end
  end

  private

  def occurrence_in_month(date)
    case date.mday
      when 1..7
        'D_1ER'
      when 8..14
        'D_2EME'
      when 15..21
        'D_3EME'
      when 22..28
        'D_4EME'
      else
        'D_DERNIER'
    end
  end

  def parse_geoloc_details
    if @informationsActivite.nil? || @informationsActivite[:prestataireActivites].nil?
      geoloc_details = @localisation[:geolocalisation]
    else
      geoloc_details = @informationsActivite[:prestataireActivites][:geolocalisation]
    end
    geoloc_details
  end

end