class AddDeliverooStatusToRestaurants < ActiveRecord::Migration
  def change
    add_column :restaurants, :deliveroo_status, :string
  end
end
