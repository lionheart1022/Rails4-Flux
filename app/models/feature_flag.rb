class FeatureFlag < ActiveRecord::Base
  ALL_IDENTIFIERS = %w(
    e-conomic-v2
    truck-driver-db
    truck-driver-app
    truck-fleet
    automated-billing
    rate-sheets
    shipment-updates
    interval-margins
    product-rules
    ups-prebook-step
    monthly-fuel
    invoice-validation
  )

  DEPRECATED_IDENTIFIERS = %w(
    complex-margins
    carrier-override-credentials
    contact-import
    carriers-v2
    reports-v2
    new-customer-carrier-overview
    new-price-document-interface
    background-report
  )

  COMPANY_SPECIFIC_IDENTIFIERS = %w(
    truck-driver-db
    truck-driver-app
    truck-fleet
    rate-sheets
    interval-margins
    product-rules
    ups-prebook-step
    monthly-fuel
    e-conomic-v2
    automated-billing
    shipment-updates
    invoice-validation
  )

  USER_SPECIFIC_IDENTIFIERS = %w(
  )

  scope :active, -> { where(revoked_at: nil) }

  belongs_to :resource, polymorphic: true, required: true

  validates :identifier, presence: true, inclusion: { in: ALL_IDENTIFIERS + DEPRECATED_IDENTIFIERS }
  validates :identifier, exclusion: { in: DEPRECATED_IDENTIFIERS }, on: :create

  before_create :revoke_existing

  class << self
    def all_options_for_user(user)
      all_options_for_resource(user, identifiers: USER_SPECIFIC_IDENTIFIERS)
    end

    def all_options_for_company(company)
      all_options_for_resource(company, identifiers: COMPANY_SPECIFIC_IDENTIFIERS)
    end

    def all_options_for_resource(resource, identifiers:)
      identifiers.map do |identifier|
        feature_flag = self.active.find_by(resource: resource, identifier: identifier)

        feature_flag || self.new(identifier: identifier)
      end
    end

    def revoke(resource:, identifier:)
      self
        .where(resource: resource, identifier: identifier)
        .update_all(revoked_at: Time.now)
    end
  end

  private

  def revoke_existing
    self.class.revoke(resource: resource, identifier: identifier)
  end
end
