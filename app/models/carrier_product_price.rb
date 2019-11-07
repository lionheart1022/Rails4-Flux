require 'tnt_price_document'
require 'dhl_price_document'
require 'ups_price_document'
require 'post_dk_price_document'
require 'unifaun_price_document'
require 'gls_price_document'
require 'gtx_price_document'
require 'price_document_v1'
require 'marshal_column'

class CarrierProductPrice < ActiveRecord::Base
  PRICE_DOCUMENT_YAML_CODER = ActiveRecord::Coders::YAMLColumn.new
  PRICE_DOCUMENT_MARSHAL_CODER = MarshalColumn.new

  belongs_to :carrier_product

  module States
    OK        = 'ok'
    WARNINGS  = 'warnings'
    FAILED    = 'failed'
  end

  validates :carrier_product, :price_document, :state, presence: true

  def price_document
    if read_attribute(:marshalled_price_document)
      PRICE_DOCUMENT_MARSHAL_CODER.load(read_attribute(:marshalled_price_document))
    else
      Rails.logger.warn "Tried to access marshalled price document instance but none was present (carrier product price ID: #{id})"
      PRICE_DOCUMENT_YAML_CODER.load(read_attribute(:price_document))
    end
  end

  def price_document=(value)
    write_attribute(:marshalled_price_document, PRICE_DOCUMENT_MARSHAL_CODER.dump(value))
    write_attribute(:price_document, PRICE_DOCUMENT_YAML_CODER.dump(value))
  end

  def parsed_without_warnings?
    state == States::OK
  end

  def parsed_with_warnings?
    state == States::WARNINGS
  end

  def failed?
    state == States::FAILED
  end

  def successful?
    parsed_without_warnings? || parsed_with_warnings?
  end
end
