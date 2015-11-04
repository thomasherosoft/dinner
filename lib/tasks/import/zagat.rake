namespace :import do
  namespace :zagat do
    task csv: :environment do
      found = total = 0
      CSV.read(ENV['FILE']).drop(1).each_with_index do |row,idx|
        if restaurant = Restaurant.search([row[2], row[12]].join(' ')).first
          restaurant.phone = row[15] if restaurant.phone.blank?
          restaurant.update website: row[16], zagat_status: 'yes'
          puts "+ #{row[2].inspect} => #{restaurant.name}"
          found += 1
        else
          puts "- #{row[2].inspect} #{row[12].inspect}"
        end
        total += 1
      end
      puts "found #{found} of #{total}"
    end
  end
end
