class AddImageurlToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :image_present, :boolean, default: false, null: false
  end
end
