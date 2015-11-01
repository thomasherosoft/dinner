class RestaurantsController < ApplicationController
  after_action :log_search

  PER_PAGE = 7

  def index
    search_opts = {
      include: [:cuisines],
      page: params[:page], per_page: PER_PAGE,
      order: {rating: :desc}
    }
    where = {}

    search_opts[:fields] = case params[:type]
                           when 'names' then [:name]
                           when 'cities' then ['area^10', 'address']
                           when 'addresses' then [:address]
                           when 'cuisines' then [:cuisines]
                           end
    search_opts[:order] = nil if search_opts[:fields].present?

    if location.present?
      search_opts[:boost_by_distance] = {
        field: :location,
        origin: location
      }
      search_opts[:order] = {
        rating: :desc,
        _geo_distance: {
          location: {lat: location.first, lon: location.last},
          order: 'asc',
          unit: 'mi'
        }
      }
    end

    if query == 'Current Location'
      @query = '*'
      if location.present?
        where[:location] = {
          near: location,
          within: '0.5mi'
        }
      end
    end

    if Hash === params[:filters]
      if (radius = params[:filters][:location].to_i) > 0
        where[:location] = { near: location, within: "#{radius}mi" }
      end

      if (cuisine = params[:filters][:cuisine]).present? && cuisine != 'all'
        where[:cuisines] = /#{cuisine.downcase}.*/
      end

      if (rating = params[:filters][:rating].to_i) > 0
        where[:rating] = {gt: rating}
      end
    end

    search_opts[:where] = where if where.present?

    respond_to do |format|
      format.html do
        if params[:search].present? || params[:filter].present?
          redirect_to action: :index
        else
          @cuisines = Cuisine.order(:name).pluck(:name)
          render layout: !request.xhr?
        end
      end
      format.json do
        @restaurants = Restaurant.search query, search_opts
        @restaurants.each_with_index do |r,i|
          r.distance = @restaurants.response['hits']['hits'][i]['sort'].try(:last)
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

  def apply_filter(relation=nil)
    if %w( michelin zagat timeout foodtruck faisal deliveroo ).include?(params[:filter])
      if relation
        attr = "#{params[:filter]}_status".to_sym
        relation.where.not(attr => nil)
      else
        {where: {filter: [params[:filter]]}}
      end
    end
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
end
