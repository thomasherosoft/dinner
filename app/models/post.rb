class Post < ActiveRecord::Base

scope :zagat_status, -> (zagat_status) { where zagat_status: zagat_status }

   validates :name, presence: true
   validates :city, presence: true
   validates :address, presence: true

   def self.search(query)
     where("name like ? OR city like ? OR address like ?", "%#{query}%", "%#{query}%", "%#{query}%")
       end
end
