require 'csv'

namespace :csv do

  desc "Import CSV Data for Michelin Star Restaurants"
  task :post => :environment do

    csv_file_path = 'db/data.csv'

    CSV.foreach(csv_file_path, "r:ISO-8859-1" ) do |row|
  Post.create({
                  :name => row[0].to_s.scrub,
                  :address => row[1].to_s.scrub,
                  :city => row[2].to_s.scrub,
                  :michelin_status => row[3],
                  :website => row[4].to_s.scrub,
                  :phone => row[5],
                  :longitude => row[6],
                  :latitude => row[7],
                  :inthenews => row[8],
                  :google_reviews => row[9]
              })
end
    end
  end
