# Rake tasks for performing data migrations
namespace :data_migrations do
  # Example of a data migration:
  #
  #   desc "Serializes price documents with Marshal"
  #   task marshal_price_documents: :environment do
  #     carrier_product_prices =
  #       CarrierProductPrice
  #       .where(marshalled_price_document: nil)
  #       .where.not(price_document: nil)
  #
  #     puts "Number of carrier product prices needing migration: #{carrier_product_prices.count}"
  #
  #     carrier_product_prices.each do |carrier_product_price|
  #       carrier_product_price.update_attributes!(price_document: carrier_product_price.price_document)
  #     end
  #   end
  #
  # Tip: A data migration task should be idempotent: it should handle being run multiple times (in case of failure or new data).

  desc "Migrate feature flag records from user to company"
  task feature_flag_user2company: :environment do
    identifiers = %w(
      e-conomic-v2
      automated-billing
      shipment-updates
    )

    FeatureFlag.transaction do
      FeatureFlag.active.where(resource_type: "User", identifier: identifiers).each do |feature_flag|
        puts "Handling FeatureFlag: #{feature_flag.inspect}"

        user = feature_flag.resource
        raise "Feature flag for User was expected" unless user.is_a?(::User)

        company = user.company
        next if user.company_id.nil?

        existing_company_feature_flags = FeatureFlag.active.where(resource: company, identifier: feature_flag.identifier)
        if existing_company_feature_flags.exists?
          puts "Feature flag for company already exists - all good"
        else
          FeatureFlag.create!(identifier: feature_flag.identifier, resource: company)
        end

        feature_flag.touch(:revoked_at) # Mark the user-level feature flag as revoked
      end
    end
  end
end
