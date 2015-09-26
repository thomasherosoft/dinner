class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :name
      t.string :inthenews
      t.string :michelin_status
      t.string :google_reviews
      t.string :address
      t.string :city
      t.string :website
      t.string :phone
      t.decimal :longitude
      t.decimal :latitude

      t.timestamps null: false
    end
  end
end
