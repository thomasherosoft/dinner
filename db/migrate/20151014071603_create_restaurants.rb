class CreateRestaurants < ActiveRecord::Migration
  def change
    create_table :restaurants do |t|
      t.string :name, null: false
      t.string :address
      t.string :phone
      t.string :city
      t.string :area
      t.decimal :latitude
      t.decimal :longitude
      t.string :zipcode
      t.integer :price_range
      t.string :price_range_currency
      t.string :photo_url
      t.string :thumb_url
      t.integer :rating
      t.string :zomato_id
      t.datetime :zomato_fetched_at
      t.string :zagat_status
      t.string :michelin_status
      t.string :timeout_status
      t.string :foodtruck_status
      t.string :faisal_status
      t.string :deliveroo_status
      t.string :google_place_id
      t.string :zomato_url
      t.string :reviews_count

      t.timestamps null: false
    end
  end
end
