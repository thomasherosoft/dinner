json.array!(@posts) do |post|
  json.extract! post, :id, :name, :zagat_status, :michelin_status, :cuisine, :address, :city, :price_range, :longitude, :latitude, :image_present
  json.url post_url(post, format: :json)
  json.page @posts.current_page
  json.pages @posts.total_pages
end
