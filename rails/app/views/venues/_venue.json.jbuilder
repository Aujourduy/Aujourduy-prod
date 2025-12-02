json.extract! venue, :id, :name, :address_line1, :address_line2, :postal_code, :city, :department_code, :department_name, :region, :country, :latitude, :longitude, :created_at, :updated_at
json.url venue_url(venue, format: :json)
