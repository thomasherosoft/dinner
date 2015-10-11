class Post < ActiveRecord::Base

   scope :zagat_status,    -> (zagat_status) { where zagat_status: zagat_status }
   scope :michelin_status, -> (michelin_status) { where michelin_status: michelin_status }
   scope :price_range, -> (price_range) { where(price_range: price_ranges(price_range)) }
   scope :cuisine, -> (cuisine) { where cuisine: cuisine }


   validates :name, presence: true
   validates :city, presence: true
   validates :address, presence: true

   default_scope ->{ order(created_at: :desc) }

   def self.price_ranges(price_range)
     res = []
     price_range.to_i.times do |i|
       res << ('$' * (i + 1))
     end
     res
   end

   def self.search(query)
     where("name like ? OR city like ? OR address like ?", "%#{query}%", "%#{query}%", "%#{query}%")
       end
end
