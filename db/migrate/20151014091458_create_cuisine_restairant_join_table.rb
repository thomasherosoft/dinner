class CreateCuisineRestairantJoinTable < ActiveRecord::Migration
  def change
    create_join_table :cuisines, :restaurants
  end
end
