class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.belongs_to :restaurant, index: true, null: false
      t.string :source, null: false
      t.string :content, null: false
      t.string :url

      t.timestamps null: false
    end
    add_index :reviews, :source
  end
end
