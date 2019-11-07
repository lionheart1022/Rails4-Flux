class EconomicAccess < ActiveRecord::Base
  scope :active, -> { where(active: true) }

  belongs_to :owner, required: true, polymorphic: true
  has_many :products, class_name: "EconomicProduct", foreign_key: "access_id"
  has_many :product_requests, class_name: "EconomicProductRequest", foreign_key: "access_id"

  validates :agreement_grant_token, presence: true

  def in_progress_product_requests
    product_requests.in_progress
  end
end
