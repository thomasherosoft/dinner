class AddPhotoToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :phone, :string
  end
end
