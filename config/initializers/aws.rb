Aws.config.update(
  credentials: Aws::SharedCredentials.new(profile_name: 'dinner'),
  region: 'eu-west-1'
)

S3_BUCKET_NAME = 'restaurantmapper-photos'
