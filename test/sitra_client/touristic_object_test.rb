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

  should 'populate contact details' do
    hash_result = {
        :informations => {
            :moyensCommunication => [
                {:type => {:libelleFr => "Téléphone"}, :coordonnee => "0123456789"},
                {:type => {:libelleFr => "Fax"}, :coordonnee => "9876543201"}
            ]
        }
    }
    touristic_object = TouristicObject.new(hash_result)

    assert_equal({'Téléphone' => '0123456789'}, touristic_object.contact)
  end

  should 'populate image details' do
    hash_result = {:imagePrincipale => {:traductionFichiers => [{:url => "my/image/url"}]}}
    touristic_object = TouristicObject.new(hash_result)

    assert_equal 'my/image/url', touristic_object.picture_url('default.png')
  end

  should 'populate address details' do
    hash_result = {
        :informationsActivite => {
            :commerceEtServicePrestataire => {
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

  should 'populate adapted tourism fields' do
    hash_result = {:prestations => {:tourismesAdaptes => [{:libelleFr => "Accessible en fauteuil roulant en autonomie"}]}}
    touristic_object = TouristicObject.new(hash_result)

    assert_true touristic_object.adapted_tourism.include?('Accessible en fauteuil roulant en autonomie')
  end

  should 'retrieve merged general and specific information' do
    hash_result = {
        :type => 'ACTIVITE',
        :informations => {
            :moyensCommunication => [
                {:type => {:libelleFr => "Téléphone"}, :coordonnee => "0123456789"}
            ]
        },
        :informationsActivite => {
            :commerceEtServicePrestataire => {
                :nom => {:libelleFr => "my_service"}
            }
        }
    }

    touristic_object = TouristicObject.new(hash_result)

    assert_equal "0123456789", touristic_object.information[:moyensCommunication][0][:coordonnee]
    assert_equal "my_service", touristic_object.information[:commerceEtServicePrestataire][:nom][:libelleFr]
  end

end
