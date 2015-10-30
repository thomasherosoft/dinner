class ChangeReviewsCountTypeInRestaurants < ActiveRecord::Migration
  def change
    change_column :restaurants, :reviews_count, :integer, default: 0, null: false, using: 'reviews_count::integer'
  end
end
