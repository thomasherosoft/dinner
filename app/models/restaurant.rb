class Restaurant < ActiveRecord::Base
  has_and_belongs_to_many :cuisines

  def cuisine_names
    cuisines.pluck(:name)
  end
end
