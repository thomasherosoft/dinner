namespace :zomato do
  task setup: :environment do
    require 'zomato' unless defined?(Zomato)
  end

  desc 'Hit zomato API with 1000calls/day limit (could be reduced by setting LIMIT environment variable)'
  task fetch: :setup do
    query = ENV['QUERY']
    raise 'not query defined' unless query.present?

    Zomato.new.search(query).each do |data|
      Restaurant.find_or_create_from_zomato_record(data)
    end
  end

  task refresh: :setup do
    zomato = Zomato.new

    arel = Restaurant.arel_table
    Restaurant.
      where.not(zomato_id: nil).
      where(
        arel[:fetched_at].lt(3.days.ago).
        or(arel[:fetched_at].eq(nil))
      ).find_each do |restaurant|
        if data = zomato.find(restaurant.zomato_id)
          restaurant.fill_from_zomato_record(data)
        end
      end
  end

  def search(zomato, name, address)
    saved = 0
    query = [name, address].join(' ')
    begin
      found = zomato.search(query)
      found.each do |result|
        if result['name'].include?(name)
          saved += 1
          record =  Restaurant.find_or_create_from_zomato_record(result)
          yield record
        end
      end
      raise if saved.zero?
    rescue
      unless query == name
        query = name
        retry
      end
    end
    puts "#{name} #{address}: results #{found.size} of #{zomato.results_count}, saved #{saved}"
  end

  task import_fk: :setup do
    require 'cvs' unless defined?(CSV)
    offset = ENV['OFFSET'].to_i
    limit = ENV['LIMIT'].to_i
    file_name = ENV['FILE'].presence or raise 'no file in env'
    zomato = Zomato.new

    CSV.read(file_name).select{|r| r[14].to_s.start_with?('020') }.drop(offset).take(limit).each do |row|
      search(zomato, row[3], row[5]) do |record|
        status = row[6].to_s.downcase
        value = michelin.scan(/\d+/).first
        # puts "save #{record.inspect} #{row[14].inspect} #{michelin.inspect}"
        michelin = if status['bib']
                     [value, (value > 1 ? 'bibs' : 'bib')].join(' ')
                   elsif status['star']
                     [value, (value > 1 ? 'stars' : 'star')].join(' ')
                   else
                     "yes"
                   end
        puts "save #{record.inspect} #{row[14].inspect} #{michelin.inspect}"
        record.update! phone: row[14], michelin_status: michelin
      end
    end
  end

  task import_zagat: :setup do
    require 'cvs' unless defined?(CSV)
    offset = ENV['OFFSET'].to_i
    offset = 1 if offset == 0 # header
    limit = ENV['LIMIT'].to_i
    file_name = ENV['FILE'].presence or raise 'no file in env'
    zomato = Zomato.new

    CSV.read(file_name).drop(offset).take(limit).each do |row|
      search(zomato, row[2], row[12]) do |record|
        record.update phone: row[15], zagat_status: 'yes'
      end
    end
  end

  task import_timeout: :setup do
    offset = ENV['OFFSET'].to_i
    limit = ENV['LIMIT'].to_i
    file_name = ENV['FILE'].presence or raise 'no file in env'
    zomato = Zomato.new

    open(file_name).read.split(/[\r\n]+/).drop(offset).take(limit).each do |row|
      name = row.strip
      search(zomato, name, nil) do |record|
        record.update timeout_status: 'yes'
      end
    end
  end

  task import_foodtruck: :setup do
    offset = ENV['OFFSET'].to_i
    limit = ENV['LIMIT'].to_i
    file_name = ENV['FILE'].presence or raise 'no file in env'
    zomato = Zomato.new

    CSV.read(file_name).drop(offset).take(limit).each do |row|
      search(zomato, row[0], row[1]) do |record|
        record.update foodtruck_status: 'yes'
      end
    end
  end

  task import_faisal: :setup do
    offset = ENV['OFFSET'].to_i
    limit = ENV['LIMIT'].to_i
    file_name = ENV['FILE'].presence or raise 'no file in env'
    zomato = Zomato.new

    open(file_name).read.split(/[\r\n]+/).drop(offset).take(limit).each do |row|
      name = row.strip
      search(zomato, name, nil) do |record|
        record.update faisal_status: 'yes'
      end
    end
  end

end