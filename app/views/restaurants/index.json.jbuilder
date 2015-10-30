json.array!(@restaurants) do |restaurant|
  json.extract! restaurant, :id, :name, :zagat_status, :michelin_status, :address, :city, :price_range, :price_range_currency, :rating, :phone, :google_place_id, :timeout_status, :area, :reviews_count
  json.url post_url(restaurant, format: :json)
  json.latitude restaurant.latitude.to_f
  json.longitude restaurant.longitude.to_f
  json.photo restaurant.photo_url.presence || image_url('item-1.jpg')
  json.page @restaurants.current_page
  json.pages @restaurants.total_pages
  json.totals @restaurants.total_entries
  json.cuisines restaurant.cuisines_names
  if @restaurants.respond_to?(:facets) && @restaurants.facets
    json.facets @restaurants.facets['filter']['terms'] do |f|
      json.set! f['term'], f['count']
    end
  end
end
