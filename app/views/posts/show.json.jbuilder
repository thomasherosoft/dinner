json.extract! @post, :id, :name, :michelin_status, :address, :city, :phone, :rating
json.latitude @post.latitude.to_f
json.longitude @post.longitude.to_f
json.photo image_url(@post.image_present ? "/post_images/#{@post.id}.jpg" : 'item-1.jpg')
