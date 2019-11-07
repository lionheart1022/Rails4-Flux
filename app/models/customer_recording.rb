require "postgres_pattern"

class CustomerRecording < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :recordable, required: true, polymorphic: true

  scope :disabled, -> { where.not(disabled_at: nil) }
  scope :enabled, -> { where(disabled_at: nil) }
  scope :in_order, -> { order(:company_scoped_id, :normalized_customer_name) }

  validates :type, presence: true
  validates :customer_name, :normalized_customer_name, presence: true

  class << self
    def normalize_customer_name(name)
      if name
        I18n.transliterate(name).downcase
      end
    end

    def autocomplete_search(customer_name: nil)
      if customer_name.present?
        where("customer_name ILIKE ?", "%#{PostgresPattern.escape(customer_name)}%")
      else
        all
      end
    end
  end

  def shipment_filter_params
    raise "define in subclass"
  end

  protected

  def normalize_string_value(value)
    self.class.normalize_customer_name(value)
  end
end
