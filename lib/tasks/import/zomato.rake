namespace :import do
  namespace :zomato do
    task restaurants: :environment do
      cols = %i(
        zomato_id name address city area
        cuisines working_hours zomato_url
        rating_score reviews_count phone gps
      )
      parsing_data = false
      CSV.foreach(ENV['FILE'], col_sep: "\t") do |row|
        unless parsing_data
          parsing_data = true
          next
        end

        db = Restaurant.find_or_initialize_by(zomato_id: row.first)
        cols.each_with_index do |col, idx|
          db.send("#{col}=", row[idx]) if db.has_attribute?(col)
        end

        db.rating = (100 * row[cols.index(:rating_score)].to_f / 5).to_i
        db.latitude, db.longitude = row.last.split.map(&:to_f)
        db.save
        db.cuisine_ids = row[cols.index(:cuisines)].split(/\s*,\s*/).map do |name|
          Cuisine.find_or_create_by(name: name).id
        end
      end
    end

    task apply_michelin: :environment do
      puts "starts reading #{ENV['FILE']}"
      misses = open('misses.txt', 'w')
      found = total = 0
      CSV.read(ENV['FILE']).select{|r| r[16].to_s.start_with?('020') }.each_with_index do |row, idx|
        query = (row[3] + ' ' + row[13]).split.
          reject{|w| %w( st rd ln pl ct sq sl at ).index(w.downcase.delete('.,')) }.
          join(' ').gsub('&amp;', '&')
        if db = Restaurant.search(query).first
          status = row[6].to_s.downcase
          value = status.scan(/\d+/).first.to_i
          value = nil if value.zero?
          michelin = if status['bib']
                       'Michelin Bib Gourmand'
                     elsif status['star']
                       [value, (value.to_i > 1 ? 'Michelin Stars' : 'Michelin Star')].join(' ')
                     else
                       'yes'
                     end
          db.update michelin_status: michelin
          puts "  #{query.inspect}"
          found += 1
        else
          misses.puts query
          puts "- #{query.inspect}"
        end
        total += 1
      end
      misses.close
      puts "found #{found}/#{total}"
    end

    task apply_zagat: :environment do
      puts "starts reading #{ENV['FILE']}"
      misses = open('misses.txt', 'w')
      found = total = 0
      CSV.read(ENV['FILE']).each do |row|
        query = ([row[2], row[12]] * ' ').split.
          reject{|w| %w( st rd ln pl ct sq sl at ).index(w.downcase.delete('.,')) }.
          join(' ').gsub('&amp;', '&')
        if db = Restaurant.search(query).first
          db.update zagat_status: 'yes'
          puts "  #{query.inspect}"
          found += 1
        else
          misses.puts query
          puts "- #{query.inspect}"
        end
        total += 1
      end
      misses.close
      puts "found #{found}/#{total}"
    end

    task apply_foodtruck: :environment do
      puts "starts reading #{ENV['FILE']}"
      misses = open('misses.txt', 'w')
      found = total = 0
      CSV.read(ENV['FILE']).each do |row|
        query = ([row[0], row[1]] * ' ').split.
          reject{|w| %w( st rd ln pl ct sq sl at ).index(w.downcase.delete('.,')) }.
          join(' ').gsub('&amp;', '&')
        if db = Restaurant.search(query).first
          db.update foodtruck_status: 'yes'
          puts "  #{query.inspect}"
          found += 1
        else
          misses.puts query
          puts "- #{query.inspect}"
        end
        total += 1
      end
      misses.close
      puts "found #{found}/#{total}"
    end

    task apply_timeout: :environment do
      puts "starts reading #{ENV['FILE']}"
      misses = open('misses.txt', 'w')
      found = total = 0
      CSV.read(ENV['FILE']).each do |row|
        query = (row[0]).split.
          reject{|w| %w( st rd ln pl ct sq sl at ).index(w.downcase.delete('.,')) }.
          join(' ').gsub('&amp;', '&')
        if db = Restaurant.search(query).first
          db.update timeout_status: 'yes'
          puts "  #{query.inspect}"
          found += 1
        else
          misses.puts query
          puts "- #{query.inspect}"
        end
        total += 1
      end
      misses.close
      puts "found #{found}/#{total}"
    end

    task apply_deliveroo: :environment do
      puts "starts reading #{ENV['FILE']}"
      misses = open('misses.txt', 'w')
      found = total = 0
      CSV.read(ENV['FILE']).each do |row|
        query = (row[0]).split.
          reject{|w| %w( st rd ln pl ct sq sl at ).index(w.downcase.delete('.,')) }.
          join(' ').gsub('&amp;', '&')
        if db = Restaurant.search(query).first
          db.update deliveroo_status: 'yes'
          puts "  #{query.inspect}"
          found += 1
        else
          misses.puts query
          puts "- #{query.inspect}"
        end
        total += 1
      end
      misses.close
      puts "found #{found}/#{total}"
    end

    task reviews: :environment do
      count = 0
      CSV.foreach(ENV['FILE'], col_sep: "\t", encoding: 'UTF-16:UTF-8', quote_char: "\b") do |row|
        next unless restaurant = Restaurant.find_by(zomato_id: row.first)
        review = restaurant.zomato_reviews.find_or_initialize_by(content: row.last)
        review.created_at = Time.zone.parse(row[1])
        review.score = row[-2].to_f
        review.save
        count += 1
      end
      puts count
    end
  end
end
