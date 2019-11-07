class Addon < ActiveRecord::Base
  belongs_to :company, required: true

  scope :active, -> { where deleted_at: nil }

  class << self
    def class_by_identifier(identifier)
      case identifier
      when "company_eod_manifest"
        ::Addons::CompanyEODManifest
      when "economic"
        ::Addons::Economic
      when "pickup"
        ::Addons::Pickup
      else
        self
      end
    end

    def scope_by_identifier(identifier)
      class_by_identifier(identifier).all
    end
  end

  def enabled?
    deleted_at.blank?
  end
end
