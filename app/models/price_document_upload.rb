require "erb"

class PriceDocumentUpload < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :carrier_product, required: true
  belongs_to :created_by, class_name: "User", required: false

  has_one :carrier_product_price, through: :carrier_product

  scope :active, -> { where active: true }

  validates :s3_object_key, presence: true

  def attach_file(io)
    s3 = AWS::S3.new(
      access_key_id: Rails.configuration.s3_storage[:access_key_id],
      secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
    )
    bucket = s3.buckets[Rails.configuration.s3_storage[:bucket]]

    self.original_filename = io.original_filename
    self.s3_object_key = "price_document_uploads/#{SecureRandom.uuid}"

    bucket.objects.create(s3_object_key, file: io.path)
  end

  def inactivate_other_uploads!
    PriceDocumentUpload
      .active
      .where(company: company)
      .where(carrier_product: carrier_product)
      .where.not(id: id)
      .update_all(active: false)
  end

  def generate_download_url
    return if s3_object_key.blank?

    s3 = AWS::S3.new(
      access_key_id: Rails.configuration.s3_storage[:access_key_id],
      secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
    )
    bucket = s3.buckets[Rails.configuration.s3_storage[:bucket]]

    s3_object = bucket.objects[s3_object_key]

    if original_filename.present?
      s3_object.url_for(:read, expires: 1.hour.to_i, response_content_disposition: %Q[attachment; filename="#{ERB::Util.url_encode(original_filename)}"])
    else
      s3_object.url_for(:read, expires: 1.hour.to_i)
    end
  end

  def read_file_from_s3
    return if s3_object_key.blank?

    s3 = AWS::S3.new(
      access_key_id: Rails.configuration.s3_storage[:access_key_id],
      secret_access_key: Rails.configuration.s3_storage[:secret_access_key]
    )
    bucket = s3.buckets[Rails.configuration.s3_storage[:bucket]]

    s3_object = bucket.objects[s3_object_key]

    s3_object.read
  end
end
