require "digest"

class CarrierProductMarginConfiguration < ActiveRecord::Base
  belongs_to :owner, polymorphic: true, required: false
  belongs_to :created_by, class_name: "User", required: false

  def generate_price_document_hash(carrier_product_price:)
    self.price_document_hash = calculate_price_document_hash(carrier_product_price: carrier_product_price)
  end

  def price_document_hash_matches?(carrier_product_price:)
    price_document_hash == calculate_price_document_hash(carrier_product_price: carrier_product_price)
  end

  private

  def calculate_price_document_hash(carrier_product_price:)
    Digest::MD5.hexdigest carrier_product_price.read_attribute(:marshalled_price_document)
  end
end
