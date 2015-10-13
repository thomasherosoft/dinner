json.array!(@posts) do |post|
  json.extract! post, :id, :name, :zagat_status, :michelin_status, :cuisine, :address, :city, :price_range, :image_present, :placeid, :rating
  json.url post_url(post, format: :json)
  json.latitude post.latitude.to_f
  json.longitude post.longitude.to_f
  json.photo image_url(post.image_present ? "/post_images/#{post.id}.jpg" : 'item-1.jpg')
  json.page @posts.current_page
  json.pages @posts.total_pages
end
