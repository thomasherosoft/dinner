class RestaurantsController < ApplicationController
  def index
    @restaurants = Restaurant.all.paginate(page: params[:page], per_page: 20)

    if params[:search]
      @restaurants = @restaurants.search(params[:search])
    end

    if params[:price_range].present?
      @restaurants = @restaurants.where(price_range: params[:price_range_from].to_i..params[:price_range_till].to_i)
    end

    if params[:cuisine].present?
      @restaurants = @restaurants.joins(:cuisines).where(cuisines: {name: params[:cuisine]})
    end

    if (filter_name = params[:filter]).present?
      if %w( michelin zagat timeout foodtruck faisal ).include?(filter_name)
        method = "#{filter_name}_status".to_sym
        @restaurants = @restaurants.where.not(method => nil)
      end
    end

    respond_to do |format|
      format.html { render layout: !request.xhr? }
      format.json
    end
  end
end
