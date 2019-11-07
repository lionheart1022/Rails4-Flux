class CarrierFeedbackFile < ActiveRecord::Base
  attr_accessor :uploaded_file

  belongs_to :company, required: true
  belongs_to :configuration, class_name: "CarrierFeedbackConfiguration"
  belongs_to :file_uploaded_by, class_name: "User", required: false

  has_many :package_updates, -> { where.not(package_recording_id: nil) }, foreign_key: "feedback_file_id"
  has_many :not_found_packages, -> { where(package_recording_id: nil) }, class_name: "PackageUpdate", foreign_key: "feedback_file_id"

  def header_label
    ""
  end

  def attach_file(io)
    s3 = AWS::S3.new(
      access_key_id: Rails.configuration.s3_storage[:access_key_id],
      secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
    )
    bucket = s3.buckets[Rails.configuration.s3_storage[:bucket]]

    self.original_filename = io.original_filename if io.respond_to?(:original_filename)
    self.s3_object_key = "carrier_feedback_files/#{SecureRandom.uuid}"

    bucket.objects.create(s3_object_key, file: io)
  end

  def assign_file_contents(io)
    self.file_contents = io.read
  end

  def parse!
    return if parsed_at?

    transaction do
      touch(:parsed_at)

      parse_file_and_persist_updates!
    end
  end

  def parse_file_and_persist_updates!
    raise "define in subclass"
  end
end
