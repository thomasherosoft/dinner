class AddGooglePlaceIdToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :google_place_id, :string
  end
end
