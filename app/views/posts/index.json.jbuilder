json.array!(@posts) do |post|
  json.extract! post, :id, :name, :zagat_status, :michelin_status, :cuisine, :address, :city, :price_range, :longitude, :latitude, :imageurl
  json.url post_url(post, format: :json)
end
