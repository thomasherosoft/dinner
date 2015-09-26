class Post < ActiveRecord::Base

   validates :name, presence: true
   validates :city, presence: true

   def self.search(query)
     where("name like ? OR city like ?", "%#{query}%", "%#{query}%")
       end
end
