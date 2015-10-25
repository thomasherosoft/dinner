class RestaurantsController < ApplicationController
  after_action :log_search

  PER_PAGE = 7

  def index
    @restaurants = Restaurant.
      order(rating: :desc).
      paginate(page: params[:page], per_page: PER_PAGE)

    search_opts = ({
      page: params[:page], per_page: PER_PAGE,
      order: {rating: :desc},
      facets: [:filter]
    })

    if params[:location].present?
      loc = params[:location].split(',').map(&:to_f)
      if loc.size == 2 && loc.reject(&:zero?).size == 2
        (search_opts[:where] ||= {})[:location] = {
          near: loc,
          within: '3mi'
        }
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
        @restaurants = if params[:luck].present?
                         Restaurant.order('random()').paginate(per_page: 5, page: 1)
                       else
                         Restaurant.search (params[:q].presence || '*'), search_opts
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
      limit: PER_PAGE
    )
    render :index
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
