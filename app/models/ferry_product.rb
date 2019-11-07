class FerryProduct < ActiveRecord::Base
  TIME_FORMAT = /\A(?<hours>[0-1][0-9]|2[0-3]):(?<minutes>[0-5][0-9])\z/

  scope :active, -> { where(disabled_at: nil) }

  belongs_to :route, class_name: "FerryRoute", required: true, touch: true
  belongs_to :carrier_product, required: false
  belongs_to :integration, class_name: "FerryProductIntegration", required: false

  validates :time_of_departure, presence: true, format: { with: TIME_FORMAT }

  def ready_for_use?
    carrier_product && !carrier_product.is_disabled? && integration && integration.ready_for_use?
  end

  def account_number
    if integration
      integration.account_number
    end
  end

  def account_number=(account_number)
    build_integration if integration.nil?
    integration.account_number = account_number
  end

  def pricing_schema_object
    return nil if pricing_schema.nil?

    if pricing_schema["type"] == "fixed_price"
      PricingSchema::FixedPrice.new(amount: pricing_schema["amount"], currency: pricing_schema["currency"])
    end
  end

  module PricingSchema
    class FixedPrice
      attr_accessor :amount
      attr_accessor :currency

      def initialize(amount:, currency:)
        self.amount = amount
        self.currency = currency
      end

      def description_label
        "Fixed price"
      end

      def amount_label
        "#{amount} #{currency}"
      end

      def calculate_cost_price(_)
        amount
      end
    end
  end
end
