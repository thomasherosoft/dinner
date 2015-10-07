require 'csv'

namespace :csv do

  desc "Import CSV Data"
  task :post => :environment do

    csv_file_path = 'db/data.csv'

    CSV.foreach(csv_file_path, "r:ISO-8859-1" ) do |row|
  Post.create({
    :name => row[0],
    :michelin_status => row[1],
    :zagat_status => row[2],
    :address => row[3],
    :city => row[4],
    :cuisine => row[5],
    :neighborhood => row[6],
    :price_range => row[7],
    :longitude => row[8],
    :latitude => row[9],
              })
end
    end
  end
