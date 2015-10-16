class RestaurantsController < ApplicationController
  def index
    @restaurants = Restaurant.
      order(rating: :desc).
      paginate(page: params[:page], per_page: 20)

    respond_to do |format|
      format.html do
        if params[:search].present? || params[:filter].present?
          redirect_to action: :index
        else
          render layout: !request.xhr?
        end
      end
      format.json do

        if params[:search]
          cuisines = Cuisine.search(params[:search]).to_a
          if cuisines.size > 0
            @found_by = cuisines.map(&:name).join(', ')
            @restaurants = @restaurants.joins(:cuisines).where(cuisines: {id: cuisines.map(&:id)})
          else
            @restaurants = @restaurants.search(params[:search])
          end
        end

        if params[:price_range].present?
          @restaurants = @restaurants.where(price_range: params[:price_range_from].to_i..params[:price_range_till].to_i)
        end

        if params[:cuisine].present?
          @restaurants = @restaurants.joins(:cuisines).where(cuisines: {name: params[:cuisine]})
        end

        if (filter_name = params[:filter]).present?
          if %w( michelin zagat timeout foodtruck faisal deliveroo ).include?(filter_name)
            method = "#{filter_name}_status".to_sym
            @restaurants = @restaurants.where.not(method => nil)
          end
        end
      end
    end
  end
end
