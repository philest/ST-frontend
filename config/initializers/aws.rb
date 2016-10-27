require 'aws-sdk'

if ENV['RACK_ENV'] != 'production'
  require 'dotenv'
  Dotenv.load
end

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
})

S3 = Aws::S3::Resource.new

# TEACHER_MATERIALS = S3.bucket('teacher-flyers')
# puts bucket.exists?

# obj = s3.bucket('teacher-flyers').object(File.basename(__FILE__))
# obj.upload_file(__FILE__)

# S3_BUCKET = Aws::S3::Resource.new.bucket('st-messenger')