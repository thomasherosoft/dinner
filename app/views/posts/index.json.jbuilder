json.array!(@posts) do |post|
  json.extract! post, :id, :name, :inthenews, :michelin_status, :google_reviews, :address, :city, :website, :phone, :longitude, :latitude
  json.url post_url(post, format: :json)
end
