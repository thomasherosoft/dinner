class AddRatingToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :rating, :float, default: 0
  end
end
