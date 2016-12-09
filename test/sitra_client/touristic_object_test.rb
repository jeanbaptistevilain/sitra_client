# encoding : UTF-8
require 'rubygems'
gem 'shoulda'
require 'test/unit'
require 'shoulda'
require 'sitra_client/touristic_object'

class TouristicObjectTest < Test::Unit::TestCase

  should 'populate title of touristic object' do
    hash_result = {:nom => {:libelleFr => "my_title"}}
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'my_title', touristic_object.title
  end

  should 'populate description of touristic object' do
    hash_result = {:presentation => {:descriptifCourt => {:libelleFr => "my_description"}}}
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'my_description', touristic_object.description
  end

  should 'populate detailed description of touristic object' do
    hash_result = {:presentation => {:descriptifDetaille => {:libelleFr => "my_detailed_description"}}}
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'my_detailed_description', touristic_object.details
  end

  should 'populate contact details for provided fields' do
    hash_result = {
        :informations => {
            :moyensCommunication => [
                {:type => {:libelleFr => "Téléphone", :id => 201}, :coordonnees => {:fr => "0123456789"}},
                {:type => {:libelleFr => "Mél", :id => 204}, :coordonnees => {:fr => "my@email.fr"}},
                {:type => {:libelleFr => "Fax", :id => 202}, :coordonnees => {:fr => "9876543201"}}
            ]
        }
    }
    touristic_object = TouristicObject.new(hash_result)

    assert_equal({'Téléphone' => '0123456789', 'Mél' => 'my@email.fr'}, touristic_object.contact([201, 204]))
  end

  should 'populate image details' do
    hash_result = {
        :illustrations => [
            {:type => 'IMAGE', :traductionFichiers => [{:url => 'my/image/url', :urlListe => 'my/list/url', :urlFiche => 'my/details/url'}]}
        ]
    }
    touristic_object = TouristicObject.new(hash_result)

    assert_equal [{:url => 'my/image/url', :urlListe => 'my/list/url', :urlFiche => 'my/details/url'}], touristic_object.pictures
  end

  should 'populate address details' do
    hash_result = {
        :informationsActivite => {
            :prestataireActivites => {
                :nom => {:libelleFr => "my_service"},
                :adresse => {:adresse1 => "my_address", :codePostal => "1234", :commune => {:nom => "my_city"}},
                :geolocalisation => {:valide => true, :geoJson => {:coordinates => [0.1, 0.2]}}
            }
        }
    }
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'my_service', touristic_object.service_provider
    assert_equal 'my_address, my_city', touristic_object.address
    assert_equal 0.2, touristic_object.latitude
    assert_equal 0.1, touristic_object.longitude
  end

  should 'use event details when available' do
    hash_result = {:informationsFeteEtManifestation => {:nomLieu => "my_place"}}
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'my_place', touristic_object.service_provider
  end

  should 'fallback to localisation address when service details are missing' do
    hash_result = {
        :localisation => {
            :adresse => {:adresse1 => "my_address", :codePostal => "1234", :commune => {:nom => "my_city"}},
            :geolocalisation => {:valide => true, :geoJson => {:coordinates => [0.1, 0.2]}}
        },
        :informationsActivite => {}
    }
    touristic_object = TouristicObject.new(hash_result)

    assert_nil touristic_object.service_provider
    assert_equal 'my_address, my_city', touristic_object.address
    assert_equal 0.2, touristic_object.latitude
    assert_equal 0.1, touristic_object.longitude
  end

  should 'populate opening hours when available' do
    hash_result = {:ouverture => {:periodeEnClair => {:libelleFr => "my_opening_hours"}}}
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'my_opening_hours', touristic_object.horaires
  end

  should 'populate tariffs data when available' do
    hash_result = {
        :descriptionTarif => {:gratuit => false,
                              :tarifsEnClair => {:libelleFr => "my_tariff_description"}
        }
    }
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'my_tariff_description', touristic_object.tarif
  end

  should 'tag free oject when relevant' do
    hash_result = {:descriptionTarif => {:gratuit => true}}
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'gratuit', touristic_object.tarif
  end

  should 'populate populations information' do
    hash_result = {
        :prestations => {:typesClientele => [{:libelleFr => "Familles"}]}
    }
    touristic_object = TouristicObject.new(hash_result)

    assert_equal ['Familles'], touristic_object.population
  end

  should 'populate prestations fields' do
    hash_result = {:prestations => {:tourismesAdaptes => [{:libelleFr => "Accessible en fauteuil roulant en autonomie"}]}}
    touristic_object = TouristicObject.new(hash_result)

    assert_true touristic_object.prestations(:tourismesAdaptes).values[0].include?('Accessible en fauteuil roulant en autonomie')
  end

  should 'retrieve merged general and specific information' do
    hash_result = {
        :type => 'ACTIVITE',
        :informations => {
            :moyensCommunication => [
                {:type => {:libelleFr => "Téléphone"}, :coordonnees => {:fr => "0123456789"}}
            ]
        },
        :informationsActivite => {
            :prestataireActivites => {
                :nom => {:libelleFr => "my_service"}
            }
        }
    }

    touristic_object = TouristicObject.new(hash_result)

    assert_equal "0123456789", touristic_object.information[:moyensCommunication][0][:coordonnees][:fr]
    assert_equal "my_service", touristic_object.information[:prestataireActivites][:nom][:libelleFr]
  end

  should 'default to fr locale' do
    hash_result = {:presentation => {:descriptifCourt => {:libelleFr => "my_description_fr", :libelleEn => "my_description_en"}}}
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'my_description_fr', touristic_object.description
  end

  should 'use provided locale when available' do
    hash_result = {:presentation => {:descriptifCourt => {:libelleFr => "my_description_fr", :libelleEn => "my_description_en"}}}
    touristic_object = TouristicObject.new(hash_result)
    touristic_object.set_locale('en')

    assert_equal 'my_description_en', touristic_object.description
  end

  should 'return predicate covering openings every day of the week' do
    opening_hash = {:type => 'OUVERTURE_TOUS_LES_JOURS'}
    predicate = TouristicObject.new({}).open_day_predicate(opening_hash)

    assert_equal true, predicate.call(Date.new(2015, 2, 8))
    assert_equal true, predicate.call(Date.new(2015, 2, 9))
    assert_equal true, predicate.call(Date.new(2015, 2, 10))
    assert_equal true, predicate.call(Date.new(2015, 2, 11))
    assert_equal true, predicate.call(Date.new(2015, 2, 12))
    assert_equal true, predicate.call(Date.new(2015, 2, 13))
    assert_equal true, predicate.call(Date.new(2015, 2, 14))
  end

  should 'return predicate covering openings all days of the week except one' do
    opening_hash = {:type => 'OUVERTURE_SAUF', :ouverturesJournalieres => [{:jour => 'DIMANCHE'}]}
    predicate = TouristicObject.new({}).open_day_predicate(opening_hash)

    assert_equal false, predicate.call(Date.new(2015, 2, 8))
    assert_equal true, predicate.call(Date.new(2015, 2, 9))
    assert_equal true, predicate.call(Date.new(2015, 2, 10))
    assert_equal true, predicate.call(Date.new(2015, 2, 11))
    assert_equal true, predicate.call(Date.new(2015, 2, 12))
    assert_equal true, predicate.call(Date.new(2015, 2, 13))
    assert_equal true, predicate.call(Date.new(2015, 2, 14))
  end

  should 'return predicate covering openings only on specified days' do
    opening_hash = {:type => 'OUVERTURE_SEMAINE', :ouverturesJournalieres => [{:jour => 'LUNDI'}, {:jour => 'MERCREDI'}, {:jour => 'VENDREDI'}]}
    predicate = TouristicObject.new({}).open_day_predicate(opening_hash)

    assert_equal false, predicate.call(Date.new(2015, 2, 8))
    assert_equal true, predicate.call(Date.new(2015, 2, 9))
    assert_equal false, predicate.call(Date.new(2015, 2, 10))
    assert_equal true, predicate.call(Date.new(2015, 2, 11))
    assert_equal false, predicate.call(Date.new(2015, 2, 12))
    assert_equal true, predicate.call(Date.new(2015, 2, 13))
    assert_equal false, predicate.call(Date.new(2015, 2, 14))
  end

  should 'return predicate covering all week days (alternative)' do
    opening_hash = {:type => 'OUVERTURE_SEMAINE', :ouverturesJournalieres => [{:jour => 'TOUS'}]}
    predicate = TouristicObject.new({}).open_day_predicate(opening_hash)

    assert_equal true, predicate.call(Date.new(2015, 2, 8))
    assert_equal true, predicate.call(Date.new(2015, 2, 9))
    assert_equal true, predicate.call(Date.new(2015, 2, 10))
    assert_equal true, predicate.call(Date.new(2015, 2, 11))
    assert_equal true, predicate.call(Date.new(2015, 2, 12))
    assert_equal true, predicate.call(Date.new(2015, 2, 13))
    assert_equal true, predicate.call(Date.new(2015, 2, 14))
  end

  should 'return predicate covering opening on a specific day of the month' do
    opening_hash = {:type => 'OUVERTURE_MOIS', :ouverturesJourDuMois => [{:jour => 'LUNDI', :jourDuMois => 'D_2EME'}]}
    predicate = TouristicObject.new({}).open_day_predicate(opening_hash)

    assert_equal false, predicate.call(Date.new(2015, 2, 2))
    assert_equal false, predicate.call(Date.new(2015, 2, 8))
    assert_equal true, predicate.call(Date.new(2015, 2, 9))
    assert_equal false, predicate.call(Date.new(2015, 2, 10))
    assert_equal false, predicate.call(Date.new(2015, 2, 11))
    assert_equal false, predicate.call(Date.new(2015, 2, 12))
    assert_equal false, predicate.call(Date.new(2015, 2, 13))
    assert_equal false, predicate.call(Date.new(2015, 2, 14))
    assert_equal false, predicate.call(Date.new(2015, 2, 16))
  end

  should 'return predicate covering openings on several days of the month' do
    opening_hash = {:type => 'OUVERTURE_MOIS',
                    :ouverturesJourDuMois => [{:jour => 'LUNDI', :jourDuMois => 'D_4EME'}, {:jour => 'MARDI', :jourDuMois => 'D_1ER'}]}
    predicate = TouristicObject.new({}).open_day_predicate(opening_hash)

    assert_equal true, predicate.call(Date.new(2015, 2, 3))
    assert_equal false, predicate.call(Date.new(2015, 2, 9))
    assert_equal false, predicate.call(Date.new(2015, 2, 10))
    assert_equal false, predicate.call(Date.new(2015, 2, 11))
    assert_equal false, predicate.call(Date.new(2015, 2, 12))
    assert_equal false, predicate.call(Date.new(2015, 2, 13))
    assert_equal false, predicate.call(Date.new(2015, 2, 14))
    assert_equal false, predicate.call(Date.new(2015, 2, 15))
    assert_equal true, predicate.call(Date.new(2015, 2, 23))
  end

  should 'return predicate covering openings on the first week of the month' do
    opening_hash = {:type => 'OUVERTURE_MOIS',
                    :ouverturesJourDuMois => [{:jour => 'TOUS', :jourDuMois => 'D_1ER'}]}
    predicate = TouristicObject.new({}).open_day_predicate(opening_hash)

    assert_equal true, predicate.call(Date.new(2015, 2, 1))
    assert_equal true, predicate.call(Date.new(2015, 2, 2))
    assert_equal true, predicate.call(Date.new(2015, 2, 3))
    assert_equal true, predicate.call(Date.new(2015, 2, 4))
    assert_equal true, predicate.call(Date.new(2015, 2, 5))
    assert_equal true, predicate.call(Date.new(2015, 2, 6))
    assert_equal true, predicate.call(Date.new(2015, 2, 7))
    assert_equal false, predicate.call(Date.new(2015, 2, 8))
  end

  should 'detect date ranges intersection' do
    touristic_object = TouristicObject.new({})

    assert_equal false, touristic_object.ranges_intersect(Date.new(2015, 1, 1), Date.new(2015, 1, 31), Date.new(2015, 2, 15), Date.new(2015, 2, 25))
    assert_equal true, touristic_object.ranges_intersect(Date.new(2015, 1, 1), Date.new(2015, 12, 31), Date.new(2015, 1, 15), Date.new(2015, 1, 25))
    assert_equal true, touristic_object.ranges_intersect(Date.new(2015, 1, 1), Date.new(2015, 1, 31), Date.new(2015, 1, 15), Date.new(2015, 2, 5))
    assert_equal true, touristic_object.ranges_intersect(Date.new(2015, 1, 20), Date.new(2015, 1, 25), Date.new(2015, 1, 15), Date.new(2015, 1, 27))
    assert_equal true, touristic_object.ranges_intersect(Date.new(2015, 1, 20), Date.new(2015, 1, 25), Date.new(2015, 1, 15), Date.new(2015, 1, 22))
    assert_equal false, touristic_object.ranges_intersect(Date.new(2014, 1, 5), Date.new(2014, 12, 25), Date.new(2015, 1, 15), Date.new(2015, 1, 22), false)
    assert_equal true, touristic_object.ranges_intersect(Date.new(2014, 1, 5), Date.new(2014, 12, 25), Date.new(2015, 1, 15), Date.new(2015, 1, 22), true)
    assert_equal true, touristic_object.ranges_intersect(Date.new(2012, 12, 25), Date.new(2013, 1, 15), Date.new(2015, 1, 8), Date.new(2015, 1, 14), true)
  end

  should 'return opening status for date with a single opening period' do
    opening_hash = {:ouverture => {
        :periodesOuvertures => [
            {:dateDebut => '2014-1-1',
             :dateFin => '2014-12-31',
             :tousLesAns => true,
             :type => 'OUVERTURE_MOIS',
             :ouverturesJourDuMois => [{:jour => 'LUNDI', :jourDuMois => 'D_1ER'}]}
        ]
    }}
    touristic_object = TouristicObject.new(opening_hash)

    assert_equal true, touristic_object.open_on?('2015-2-2', '2015-2-2')
    assert_equal true, touristic_object.open_on?('2015-2-1', '2015-2-5')
    assert_equal true, touristic_object.open_on?('2015-3-1', '2015-3-10')
    assert_equal true, touristic_object.open_on?('2016-3-1', '2016-3-10')
    assert_equal false, touristic_object.open_on?('2015-2-9', '2015-2-9')
    assert_equal false, touristic_object.open_on?('2015-2-3', '2015-2-10')
  end

  should 'return opening status for date with multiple opening period' do
    opening_hash = {:ouverture => {
        :periodesOuvertures => [{:dateDebut => '2014-1-1',
                                 :dateFin => '2014-12-31',
                                 :tousLesAns => true,
                                 :type => 'OUVERTURE_MOIS',
                                 :ouverturesJourDuMois => [{:jour => 'LUNDI', :jourDuMois => 'D_1ER'}]},
                                {:dateDebut => '2015-1-1',
                                 :dateFin => '2015-1-31',
                                 :tousLesAns => false,
                                 :type => 'OUVERTURE_SEMAINE',
                                 :ouverturesJournalieres => [{:jour => 'LUNDI'}, {:jour => 'MARDI'}, {:jour => 'JEUDI'}]}]
    }}
    touristic_object = TouristicObject.new(opening_hash)

    assert_equal true, touristic_object.open_on?('2015-2-2', '2015-2-2')
    assert_equal true, touristic_object.open_on?('2015-2-1', '2015-2-5')
    assert_equal true, touristic_object.open_on?('2015-3-1', '2015-3-10')
    assert_equal true, touristic_object.open_on?('2016-3-1', '2016-3-10')
    assert_equal true, touristic_object.open_on?('2015-1-5', '2016-1-5')
    assert_equal true, touristic_object.open_on?('2015-1-12', '2015-1-12')
    assert_equal true, touristic_object.open_on?('2015-1-6', '2015-1-16')
    assert_equal true, touristic_object.open_on?('2015-1-8', '2015-1-8')
    assert_equal false, touristic_object.open_on?('2015-2-9', '2015-2-9')
    assert_equal false, touristic_object.open_on?('2015-2-3', '2015-2-10')
  end

  should 'populate informations hebergement collectif for provided fields' do
    hash_results = {
        informationsHebergementCollectif: {
            labels: [{id: '1256'},
                     {id: '5478'},
                     {id: '7899'}]
        }
    }

    touristic_object = TouristicObject.new(hash_results)

    assert_equal('1256', touristic_object.certification[0])
    assert_equal('5478', touristic_object.certification[1])
    assert_equal('7899', touristic_object.certification[2])
    assert_not_equal('5555', touristic_object.certification[2])
  end

  should 'populate informations hebergement locatif for provided fields' do
    hash_results = {
        informationsHebergementLocatif: {
            labels: [{id: '1256'},
                     {id: '5478'},
                     {id: '7899'}]
        }
    }

    touristic_object = TouristicObject.new(hash_results)

    assert_equal('1256', touristic_object.certification[0])
    assert_equal('5478', touristic_object.certification[1])
    assert_equal('7899', touristic_object.certification[2])
    assert_not_equal('5555', touristic_object.certification[2])
  end

  should 'return specific info of the touristic object' do
    array_types = ['ACTIVITE', 'COMMERCE_ET_SERVICE', 'DEGUSTATION', 'DOMAINE_SKIABLE', 'EQUIPEMENT', 'FETE_ET_MANIFESTATION',
                 'HEBERGEMENT_COLLECTIF', 'HEBERGEMENT_LOCATIF', 'HOTELLERIE', 'HOTELLERIE_PLEIN_AIR',
                 'PATRIMOINE_CULTUREL', 'PATRIMOINE_NATUREL', 'RESTAURATION', 'SEJOUR_PACKAGE', 'STRUCTURE', 'TERRITOIRE']

    expected = ['activite', 'commerceEtService', 'degustation', 'domaineSkiable', 'equipement', 'feteEtManifestation', 'hebergementCollectif',
                'hebergementLocatif', 'hotellerie', 'hotelleriePleinAir', 'patrimoineCulturel', 'patrimoineNaturel', 'restauration',
                'sejourPackage', 'structure', 'territoire']

    results = []

    array_types.each do |type|
      hash_results = { type: type }
      touristic_type = TouristicObject.new(hash_results)
      results << touristic_type.specific_info
    end

    assert_equal expected, results
  end

  should 'populate sub type label for provided fields' do
    hash_results = {
        type: 'HOTELLERIE_PLEIN_AIR',
        informationsHotelleriePleinAir: {
            hotelleriePleinAirType: {
                libelleFr: 'label'
            }
        }
    }

    touristic_object = TouristicObject.new(hash_results)

    assert_equal('label', touristic_object.sub_type)
  end


end
