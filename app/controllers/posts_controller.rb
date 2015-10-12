require 'open-uri'

class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy, :image, :rating]

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

  def image
    if request.post?
      open("public/post_images/#{@post.id}.jpg", 'wb') do |f|
        f.write open(params[:data]).read
      end
      @post.update image_present: true
      head :ok
    else
      render json: {data: (@post.image_present ? "/post_images/#{@post.id}.jpg" : nil)}
    end
  end

  def rating
    if request.post?
      @post.update(rating: params[:data])
      head :ok
    else
      render json: {data: @post.rating}
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
