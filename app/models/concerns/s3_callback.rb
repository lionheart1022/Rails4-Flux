module S3Callback
  extend ActiveSupport::Concern
  
  def s3_copy_file_between_buckets(asset: nil, filepath: nil, filename: nil)
    @s3_filepath = URI.unescape(filepath)
    
    s3 = AWS::S3.new(
      access_key_id:     Rails.configuration.s3_storage[:access_key_id],
      secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
    )
    
    # Read source file form S3
    s3_source_file = s3.buckets[s3_source_bucket].objects[s3_source_filename]
    
    # Update paperclip attributes
    asset.attachment_file_name    = filename
    asset.attachment_content_type = MIME::Types.type_for(asset.attachment_file_name).first.to_s
    asset.attachment_file_size    = s3_source_file.content_length
    asset.attachment_updated_at   = Time.now
    asset.save!
    
    # Copy file from upload to storage bucket
    asset_uri = URI::parse(asset.attachment.url(:original, timestamp: false))
    s3_stored_file = s3_source_file.copy_to(asset_uri.path[1..-1], :bucket_name => Rails.configuration.s3_storage[:bucket], :acl => :public_read)
    asset.attachment_fingerprint = s3_stored_file.etag.gsub('"', '')
    asset.save!
  end
  
  def s3_source_bucket
    s3_split_filename.first
  end
  
  def s3_source_filename
    s3_split_filename[1..-1].join("/")
  end
  
  def s3_split_filename
    # IE10 returns a filepath without a slash at the beginning, while IE9 and below, FF, safari etc. returns filepath beginning with slash.
    @s3_filepath = "/#{@s3_filepath}" unless @s3_filepath.start_with?("/")
    @s3_filepath.split(File::SEPARATOR).map {|x| x=="" ? File::SEPARATOR : x}[1..-1]
  end
  
end
