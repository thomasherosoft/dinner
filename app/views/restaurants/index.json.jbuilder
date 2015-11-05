json.array!(@restaurants) do |restaurant|
  json.extract! restaurant, :id, :name, :zagat_status, :michelin_status, :address, :city, :price_range, :price_range_currency, :rating, :phone, :google_place_id, :timeout_status, :area, :reviews_count, :newly_opened, :website
  json.latitude restaurant.latitude.to_f
  json.longitude restaurant.longitude.to_f
  if restaurant.photoid.present?
    json.photo "//restaurantmapper-photos.s3.amazonaws.com/#{restaurant.photoid}.jpg"
  else
    json.photo image_url('item-1.jpg')
  end
  json.page @restaurants.current_page
  json.pages @restaurants.total_pages
  json.totals @restaurants.total_entries
  json.cuisines restaurant.cuisines.map(&:name)
  json.miles restaurant.distance

  if restaurant.distance.present? && restaurant.distance <= 50
    time = restaurant.distance / 9 * 60
    cost = 2.5 + 1.25*restaurant.distance + 0.25*time
    if cost < 5
      json.cost 5
    else
      json.cost cost.round
    end
  end

  json.telegraph_review_url restaurant.reviews.select{|r| r.source == 'TelegraphReview' }.first.try(:url)
end
