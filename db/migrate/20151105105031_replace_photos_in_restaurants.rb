class ReplacePhotosInRestaurants < ActiveRecord::Migration
  def change
    change_table :restaurants do |t|
      t.remove :photo_url
      t.remove :thumb_url
      t.string :photoid
    end
  end
end
