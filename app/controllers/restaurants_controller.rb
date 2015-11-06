class RestaurantsController < ApplicationController
  after_action :log_search

  PER_PAGE = 7

  def index
    search_params[:fields] = case params[:type]
                             when 'names' then [:name]
                             when 'cities' then ['area^10', 'address']
                             when 'addresses' then [:address]
                             when 'cuisines' then [:cuisines]
                             else []
                             end

    if lower_query == 'current location' || query == '*'
      query_words.clear
      if location.present?
        search_where[:location] = { near: location, within: '0.5mi' }
        if Hash === params[:filters] && (radius = params[:filters][:location].to_i) > 0
          search_where[:location] = { near: location, within: "#{radius}mi" }
        end
      end
    else
      if (idx = query_words.index('near')) && query_words[idx+1] == 'me'
        query_words.slice! idx, 2
        if location.present?
          search_params[:order] = {
            _geo_distance: {
              location: {lat: location.first, lon: location.last},
              order: 'asc',
              unit: 'mi'
            },
            rating: :desc
          }
        end
      end

      if idx = query_words.index('best')
        query_words.delete_at idx
        # search_order.delete :_score
      end

      areas = []
      cuisines = []
      query_words.delete_if do |w|
        if areas_cached.include?(w)
          areas << w
        elsif cuisines_cached.include?(w)
          cuisines << w
        elsif cities_cached.include?(w)
          true
        end
      end
      search_where[:area] = areas unless areas.empty?
      search_where[:cuisines] = cuisines unless cuisines.empty?

      if (query_words.index('new') && lower_query['restaurant']) || (query_words.index('newly') && lower_query['open'])
        query_words.clear
        search_fields.clear
        search_order.delete :_score
        search_where[:newly_opened] = true
      end
    end

    if Hash === params[:filters]
      if (cuisine = params[:filters][:cuisine]).present? && cuisine != 'all'
        search_where[:cuisines] = [cuisine.downcase]
      end

      if (rating = params[:filters][:rating].to_i) > 0
        search_where[:rating] = {gte: rating}
      end
    end
    if search_fields.empty?
      search_params[:fields] = ['name^2']
    end

    # logger.debug ">> query #{query_words.inspect} => #{(query_words.join(' ').presence || '*').inspect}"
    # logger.debug search_params.inspect

    respond_to do |format|
      format.html
      format.json do
        begin
          @restaurants = Restaurant.search (query_words.join(' ').presence || '*'), search_params
          raise if @restaurants.total_count == 0
        rescue
          if (idx = query_words.index('in') || query_words.index('near') || query_words.index('around'))
            query_words.delete_at idx
            retry
          elsif search_fields.present?
            search_params.delete :fields
            retry
          elsif search_where.present?
            @query_words = nil
            search_params[:operator] = 'and'
            search_params.delete :where
            retry
          elsif search_params[:operator] == 'and'
            search_params[:operator] = 'or'
            retry
          end
        end
        if distance_idx = search_params[:order].keys.index(:_geo_distance)
          @restaurants.each_with_hit do |r,h|
            r.distance = h['sort'][distance_idx]
          end
        end
      end
    end
  end

  def suggestions
    head :ok
  end

  def autocomplete
    @restaurants = Restaurant.search(
      params[:q],
      fields: [
        {name: :word_start},
        {address: :word_start},
        {area: :word_start},
        {cuisines: :word_start}
      ],
      highlight: true,
      limit: PER_PAGE
    )

    names = []
    addresses = []
    areas = []
    cuisines = []
    @restaurants.response['hits']['hits'].each do |hit|
      hit['highlight'].each do |k,v|
        case k.to_s.split('.').first
        when 'name' then names << v
        when 'address' then addresses << v
        when 'area' then areas << v
        when 'cuisines' then cuisines << v
        end
      end
    end

    result = {}
    ary = names.flatten.uniq
    result[:names] = ary unless ary.blank?
    ary = addresses.flatten.uniq
    result[:addresses] = ary unless ary.blank?
    ary = areas.flatten.uniq
    result[:cities] = ary unless ary.blank?
    ary = cuisines.flatten.uniq
    result[:cuisines] = ary unless ary.blank?

    render json: result
  end

  private

  def log_search
    Search.create log_line: params.except(:action, :controller)
  end

  def parse_location(input)
    loc = input.to_s.split(',').map(&:to_f)
    loc.size == 2 && loc.reject(&:zero?).size == 2 ? loc : []
  end

  def location
    @location ||= parse_location params[:location]
  end

  def query
    @query ||= params[:q].presence || params[:query].presence || '*'
  end

  def lower_query
    @lower_query ||= query.downcase
  end

  def query_words
    @query_words ||= lower_query.split
  end

  def cuisines_cached
    @cuisines ||= Rails.cache.fetch('cuisines', expires_in: 1.day) do
      Cuisine.pluck(:name).map(&:downcase).uniq - ['drinks only', 'bubble tea', 'coffee and tea', 'juices', 'cafe']
    end
  end

  def areas_cached
    @areas ||= Rails.cache.fetch('areas', expires_in: 1.day) do
      Restaurant.pluck(:area).reject(&:blank?).map(&:downcase).uniq
    end
  end

  def cities_cached
    @cities ||= Rails.cache.fetch('cities', expires_in: 1.day) do
      Restaurant.pluck(:city).reject(&:blank?).map(&:downcase).uniq
    end
  end

  def search_params
    @search_params ||= {
      include: [:cuisines, :reviews],
      fields: [],
      operator: 'or',
      where: {},
      order: {
        _score: :desc,
        rating: :desc,
      },
      page: params[:page],
      per_page: (params[:mobile] == 'true' ? 25 : PER_PAGE)
    }.tap do |h|
      if location.present?
        h[:order][:_geo_distance] = {
          location: {lat: location.first, lon: location.last},
          order: 'asc',
          unit: 'mi'
        }
      end
    end
  end

  def search_fields
    search_params[:fields]
  end

  def search_where
    search_params[:where]
  end

  def search_order
    search_params[:order]
  end
end
