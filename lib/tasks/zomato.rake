namespace :zomato do

  desc 'Hit zomato API with 1000calls/day limit (could be reduced by setting LIMIT environment variable)'
  task fetch: :environment do
    query = ENV['QUERY']
    raise 'not query defined' unless query.present?

    limit = ENV['LIMIT'].to_i
    limit = 1000 if limit.zero? || limit > 1000

    config = Hashie::Mash.new Rails.application.config_for('zomato')

    headers = {Accept: 'application/json', user_key: config.api_key}
    Typhoeus::Config.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36'

    hits = 0
    offset = 0
    at_end = false


    limit.times do
      url = [
        config.url,
        URI.encode_www_form(entity_id: config.city_id, entity_type: 'city', start: offset, q: query)
      ].join('?')

      Typhoeus::Request.new(url, headers: headers).tap do |req|
        req.on_complete do |res|
          hits += 1
          puts '#%3d (+%d) => %s' % [hits, offset, (res.success? ? 'OK' : res.code)]
          if res.success?
            json = JSON.load res.body
            found = json['results_found'].to_i
            puts 'too much results for query' if found > 100
            offset = json['results_start'].to_i + json['results_shown'].to_i
            at_end = offset <= found

            json['restaurants'].each do |data|
              data = data['restaurant']
              db = Restaurant.find_or_initialize_by(
                name: data['name'],
                latitude: data['location']['latitude'].to_d,
                longitude: data['location']['longitude'].to_d)
              db.address = data['location']['address']
              db.city = data['location']['city']
              db.zipcode = data['location']['zipcode']
              db.price_range = 100 * data['price_range'].to_f / 5
              db.photo_url = data['featured_image']
              db.thumb_url = data['thumb']
              db.rating = 100 * data['user_rating']['aggregate_rating'].to_f / 5
              db.fetched_at = Time.current
              db.save
              db.cuisine_ids = data['cuisines'].split(/[\s,]+/).
                map{|c| Cuisine.find_or_create_by(name: c) }.
                map(&:id)
            end
          elsif res.timed_out?
            # TODO retry
            sleep 0.1
          else
            at_end = 0
          end
        end
        req.run
      end

      break if at_end
    end
  end

  task refresh: :environment do
    arel = Restaurant.arel_table
    Restaurant.
      where(arel[:fetched_at].lt(3.days.ago).
            or(arel[:fetched_at].eq(nil))).
      limit(100).pluck(:name).
      each do |name|
        ENV['QUERY'] = name
        Rake::Task['zomato:fetch'].invoke
      end
  end

end
