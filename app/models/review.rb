class Review < ActiveRecord::Base
  self.inheritance_column = :source

  belongs_to :restaurant

  scope :telegraph_reviews, ->{ where(source: 'TelegraphReview') }
  scope :zomato_reviews, ->{ where(source: 'ZomatoReview') }

  validates_presence_of :content
end
