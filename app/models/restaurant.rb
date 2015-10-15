class Restaurant < ActiveRecord::Base
  has_and_belongs_to_many :cuisines

  def self.find_or_create_from_zomato_record(data)
    find_or_initialize_by(
      name: data['name'],
      latitude: data['location']['latitude'].to_d,
      longitude: data['location']['longitude'].to_d
    ).tap{|record| record.fill_from_zomato_record(data) }
  end

  def self.search(query)
    where("name like ? OR city like ? OR address like ?", "%#{query}%", "%#{query}%", "%#{query}%")
  end

  def cuisines_names
    cuisines.pluck(:name)
  end

  def fill_from_zomato_record(data)
    transaction do
      self.address = data['location']['address']
      self.city = data['location']['city']
      self.zipcode = data['location']['zipcode']
      self.price_range = data['price_range'].to_i
      self.price_range_currency = data['currency']
      self.photo_url = data['featured_image']
      self.thumb_url = data['thumb']
      self.rating = 100 * data['user_rating']['aggregate_rating'].to_f / 5
      self.rating += rand(10)-5
      self.zomato_id = data['id']
      self.zomato_fetched_at = Time.current
      save
      self.cuisine_ids = data['cuisines'].split(/[\s,]+/).
        map{|c| Cuisine.find_or_create_by(name: c) }.
        map(&:id)
    end
  end
end
