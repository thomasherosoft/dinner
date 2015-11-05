namespace :import do
  namespace :photos do
    task csv: :environment do
      require 'open3'
      s3 = Aws::S3::Client.new
      count = 0

      CSV.foreach(ENV['FILE'], col_sep: "\t", encoding: 'UTF-16:UTF-8') do |row|
        next unless restaurant = Restaurant.where(photoid: nil, zomato_id: row.first).first
        uuid = SecureRandom.uuid
        bin = Base64.decode64 row.last.split('base64,', 2).last
        raw, err, status = Open3.capture3('convert jpg:- -resize 400x -strip jpg:-', stdin_data: bin, binmode: true)
        if status.success?
          s3.put_object(
            acl: 'public-read',
            body: raw,
            bucket: S3_BUCKET_NAME,
            key: "#{uuid}.jpg"
          )
          restaurant.update(photoid: uuid)
          count += 1
          puts "\t#{count}"
        else
          puts err
        end
      end
    end
  end
end
