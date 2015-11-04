namespace :import do
  namespace :telegraph do
    task articles: :environment do
      count = 0
      head = nil
      open(ENV['FILE']).read.encode('utf-8', 'utf-16').each_line do |l|
        head = true
        next unless head

        url, title, _, text = l.strip.split("\t")

        name = title.
          sub(/restaua?rants? reviews?:?/i, '').
          sub(/london (restaurant|pub) guide:?/i, '').
          sub(/crunch lunch:?/i, '').
          sub(/:?restaurants?:?/i, '').
          sub(/:?reviews?:?/i, '').
          split(',').first.strip.delete(':')

        found = false
        Restaurant.search(name, fields: [:name], order: {rating: :desc}).each do |restaurant|
          if restaurant.name.downcase[name.downcase]
            count += 1

            # puts "++ #{title.inspect} => #{name.inspect} => #{restaurant.name.inspect}"

            TelegraphReview.
              find_or_initialize_by(url: url).
              update(restaurant_id: restaurant.id, content: text)
            # puts "+ #{count}"
            found = true
            break
          end
        end
        puts "#{name.inspect} => #{l}" unless found
      end
    end
  end
end
