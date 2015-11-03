class Restaurant < ActiveRecord::Base
  has_and_belongs_to_many :cuisines

  scope :search_import, -> { includes(:cuisines) }

  attr_accessor :distance

  validates_presence_of :name

  searchkick highlight: [:name, :address, :area, :cuisines],
             locations: ['location'],
             settings: {number_of_shards: 1},
             word_start: [:name, :address, :area]

  def self.find_or_create_from_zomato_record(data)
    find_or_initialize_by(
      name: data['name'],
      latitude: data['location']['latitude'].to_d,
      longitude: data['location']['longitude'].to_d
    ).tap{|record| record.fill_from_zomato_record(data) }
  end

  def cuisines_names
    cuisines.pluck(:name)
  end

  def fill_from_zomato_record(data, do_save=true)
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
      self.rating = 99 if rating > 99
      self.rating = 5 if rating < 5
      self.zomato_id = data['id']
      self.zomato_fetched_at = Time.current
      self.latitude = data['location']['latitude'].to_d if latitude.to_f == 0
      self.longitude = data['location']['longitude'].to_d if longitude.to_f == 0
      self.name = data['name'] if name.blank?
      save if do_save
      self.cuisine_ids = data['cuisines'].split(/[\s,]+/).
        map{|c| Cuisine.find_or_create_by(name: c) }.
        map(&:id)
    end
  end

  def search_data
    filters = []
    filters << 'michelin' if michelin_status.present?
    filters << 'zagat' if zagat_status.present?
    filters << 'timeout' if timeout_status.present?
    filters << 'foodtruck' if foodtruck_status.present?
    filters << 'faisal' if faisal_status.present?
    filters << 'deliveroo' if deliveroo_status.present?
    {
      address: address,
      area: area.try(:downcase),
      cuisines: cuisines.map(&:name).map(&:downcase),
      filter: filters,
      location: [latitude, longitude].map(&:to_f),
      name: name,
      rating: rating,
      newly_opened: newly_opened
    }
  end

  def should_index?
    latitude.to_f != 0 && longitude.to_f != 0
  end
end
