class CustomerImport < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :created_by, class_name: "User"
  has_many :rows, class_name: "CustomerImportRowRecord"

  module States
    CREATED     = 'created'
    IN_PROGRESS = 'in_progress'
    FAILED      = 'failed'
    COMPLETE    = 'complete'
  end

  scope :in_progress, -> { where(status: States::IN_PROGRESS) }

  def validated_plain_rows
    rows.map do |row_record|
      plain_row = row_record.as_plain_row
      plain_row.validate
      plain_row
    end
  end

  def attach_file(io)
    self.file_metadata = {}

    if Rails.env.test?
      file_metadata["type"] = "base64_inline"
      file_metadata["base64_encoded"] = Base64.encode64(io.read)

      true
    else
      s3 = AWS::S3.new(
        access_key_id: Rails.configuration.s3_storage[:access_key_id],
        secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
      )
      bucket = s3.buckets[Rails.configuration.s3_storage[:bucket]]

      file_metadata["original_filename"] = io.original_filename if io.respond_to?(:original_filename)
      file_metadata["s3_object_key"] = "customer_imports/#{SecureRandom.uuid}"

      bucket.objects.create(file_metadata["s3_object_key"], file: io)
    end
  end

  def read_file(&block)
    if Rails.env.test?
      yield Base64.decode64(file_metadata["base64_encoded"])
    else
      return if file_metadata["s3_object_key"].blank?

      s3 = AWS::S3.new(
        access_key_id: Rails.configuration.s3_storage[:access_key_id],
        secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
      )
      bucket = s3.buckets[Rails.configuration.s3_storage[:bucket]]

      s3_object = bucket.objects[file_metadata["s3_object_key"]]
      s3_object.read(&block)
    end
  end

  def stage_completed?(stage)
    case stage
    when "parsing"
      parsing_completed?
    when "creating"
      creating_completed?
    end
  end

  def parsing?
    parsing_enqueued_at? && parsing_completed_at.nil? && !failed?
  end

  def parsing_completed?
    parsing_enqueued_at? && (failed? || parsing_completed_at?)
  end

  def creating?
    perform_enqueued_at? && perform_completed_at.nil? && !failed?
  end

  def creating_completed?
    perform_enqueued_at? && (failed? || perform_completed_at?)
  end

  def failed?
    status == States::FAILED
  end

  def parse_in_background
    return if new_record?
    CustomerImportParseJob.perform_later(id)
  end

  def perform_in_background
    return if new_record?
    CustomerImportPerformJob.perform_later(id)
  end
end
