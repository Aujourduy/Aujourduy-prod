require 'net/http'
require 'json'

class GeocodingService
  BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

  def self.geocode(address)
    api_key = ENV['GOOGLE_MAPS_API_KEY']
    return { success: false, error: 'API key manquante' } if api_key.blank?

    encoded_address = URI.encode_www_form_component(address)
    url = "#{BASE_URL}?address=#{encoded_address}&key=#{api_key}"
    
    begin
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        
        if data['status'] == 'OK' && data['results'].any?
          location = data['results'].first['geometry']['location']
          {
            success: true,
            latitude: location['lat'].round(6),
            longitude: location['lng'].round(6),
            formatted_address: data['results'].first['formatted_address']
          }
        else
          { success: false, error: "Adresse non trouvée : #{data['status']}" }
        end
      else
        { success: false, error: "Erreur API : #{response.code}" }
      end
    rescue => e
      { success: false, error: "Erreur réseau : #{e.message}" }
    end
  end
end
