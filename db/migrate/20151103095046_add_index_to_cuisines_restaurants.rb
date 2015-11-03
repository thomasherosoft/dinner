class AddIndexToCuisinesRestaurants < ActiveRecord::Migration
  def change
    add_index :cuisines_restaurants, :restaurant_id
  end
end
