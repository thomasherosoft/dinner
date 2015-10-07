class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :name
      t.string :michelin_status
      t.string :zagat_status
      t.string :address
      t.string :city
      t.string :cuisine
      t.string :neighborhood
      t.string :price_range
      t.decimal :longitude
      t.decimal :latitude

      t.timestamps null: false
    end
  end
end
