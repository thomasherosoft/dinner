class AddNewlyOpenedToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :newly_opened, :boolean, default: false, null: false
  end
end
