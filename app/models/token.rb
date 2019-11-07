class Token < ActiveRecord::Base

  # Associations
  belongs_to :owner, :polymorphic => true

  # Validations
  validates_uniqueness_of :owner_id, scope: [:type, :owner_type]

  # The default on the DB-level is true, so this callback is a work-around for disabling the flag in dev/test.
  before_create :do_not_force_ssl, if: Proc.new { |_| Rails.env.development? || Rails.env.test? }

  class << self
    # Finders
    #

    def find_company_token_by_value(value: nil)
      self.where(value: value, owner_type: Company.to_s).first
    end

    def find_customer_token_by_value(value: nil)
      self.where(value: value, owner_type: Customer.to_s).first
    end

    def find_company_token(company_id: nil)
      self.where(owner_id: company_id, owner_type: Company.to_s).first
    end

    def find_company_customer_token(company_id: nil, customer_id: nil)
      Token.joins("LEFT JOIN customers ON customers.id = tokens.owner_id AND owner_type = 'Customer'").where('customers.company_id = ? AND customers.id = ?', company_id, customer_id).first
    end

    def find_customer_from_token_value(value: nil)
      self.find_customer_token_by_value(value: value).try(:owner)
    end

    def generate_token
      SecureRandom.hex.to_s
    end

  end

  # Instance
  #

  def is_customer?
    self.owner_type == 'Customer'
  end

  def is_company?
    self.owner_type == 'Company'
  end

  private

  def do_not_force_ssl
    self.force_ssl = false

    true
  end
end
