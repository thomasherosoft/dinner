class RestaurantsController < ApplicationController
  after_action :log_search

  def index
    @restaurants = apply_filter Restaurant.
      order(rating: :desc).
      paginate(page: params[:page], per_page: 20)

    search_opts = ({
      page: params[:page], per_page: 20,
      order: {rating: :desc}
    }).merge(apply_filter || {})

    if params[:search_location].present?
      loc = params[:search_location].split(',').map(&:to_f)
      if loc.size == 2 && loc.reject(&:zero?).size == 2
        (search_opts[:where] ||= {})[:location] = {
          near: loc,
          within: '10mi'
        }
        params[:search_location] = '*'
      end
    end

    respond_to do |format|
      format.html do
        if params[:search].present? || params[:filter].present?
          redirect_to action: :index
        else
          render layout: !request.xhr?
        end
      end
      format.json do
        cuisines = params[:search_name].present? ? Cuisine.search(params[:search_name]).to_a : []
        if cuisines.size > 0
          @found_by = cuisines.map(&:name).join(', ')
          @restaurants = @restaurants.
            joins(:cuisines).
            where(cuisines: {id: cuisines.map(&:id)})
        elsif (query = params[:search_name]).present?
          @restaurants = Restaurant.search query, search_opts.merge(fields: [{name: :word_start}])
        elsif (query = params[:search_location]).present?
          @restaurants = Restaurant.search query, search_opts.merge(fields: [{address: :word_start}])
        end
      end
    end
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
end
