class AddImageurlToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :imageurl, :text
  end
end
