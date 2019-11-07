require 'aws-sdk'

# Rails.configuration.aws is used by AWS and S3DirectUpload
Rails.configuration.aws = YAML.load(ERB.new(File.read("#{Rails.root}/config/s3_inbox_buckets.yml")).result)[Rails.env].symbolize_keys!
AWS.config(logger: Rails.logger)
AWS.config(Rails.configuration.aws)

# Rails.configuration.s3_storage is used by paperclip (Files are copied to here)
Rails.configuration.s3_storage = YAML.load(ERB.new(File.read("#{Rails.root}/config/s3_storage_buckets.yml")).result)[Rails.env].symbolize_keys!
