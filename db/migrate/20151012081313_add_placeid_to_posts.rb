class AddPlaceidToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :placeid, :string
  end
end
