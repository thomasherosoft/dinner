require 'open-uri'

class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy, :info]

  # GET /posts
  # GET /posts.json
  def index
    @posts = Post.all.paginate(page: params[:page], per_page: 20)

    if params[:search]
      @posts = @posts.search(params[:search]).order(created_at: :desc)
    end

    if params[:zagat_status].present?
      @posts = @posts.zagat_status(params[:zagat_status])
    end

    if params[:michelin_status].present?
      @posts = @posts.michelin_status(params[:michelin_status])
    end

    if params[:price_range].present?
      @posts = @posts.price_range(params[:price_range])
    end

    if params[:cuisine].present?
      @posts = @posts.cuisine(params[:cuisine])
    end

    respond_to do |format|
      format.html { render layout: !request.xhr? }
      format.json
    end
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: 'Post was successfully created.' }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: 'Post was successfully updated.' }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def info
    if request.post?
      if params[:photo].present?
        open("public/post_images/#{@post.id}.jpg", 'wb') do |f|
          f.write open(params[:photo]).read
        end
        @post.update image_present: File.exists?(Rails.root.join("public/post_images/#{@post.id}.jpg"))
      end

      if params[:rating].present?
        @post.update(rating: params[:rating])
      end

      if params[:placeid].present?
        @post.update(placeid: params[:placeid])
      end

      if params[:phone].present?
        @post.update(phone: params[:phone])
      end
      head :ok
    else
      render json: {
        photo: (@post.image_present ? "/post_images/#{@post.id}.jpg" : nil),
        placeid: @post.placeid,
        rating: @post.rating
      }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def post_params
      params.require(:post).permit(:name, :michelin_status, :zagat_status,
      :address, :city, :cuisine, :neighborhood, :price_range, :longitude,
      :latitude)
    end
end
