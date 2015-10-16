class Cuisine < ActiveRecord::Base
  has_and_belongs_to_many :restaurants

  def self.search(query)
    ary = query.to_s.downcase.split
    where(('lower(name) like ? OR ' * ary.size)[0..-4], *ary)
  end
end
