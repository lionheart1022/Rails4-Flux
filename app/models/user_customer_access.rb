class UserCustomerAccess < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :customer, required: true
  belongs_to :user, required: true

  scope :active, -> { where(revoked_at: nil) }

  class << self
    def find_by_params_identifier(identifier)
      identifier.present? ? find_by(customer_id: identifier) : nil
    end

    def with_company_domain(domain)
      company = Company.find_by_domain(domain)
      company ? where(company: company) : self
    end

    def revoke_all(params)
      active.where(params).each(&:revoke!)
    end
  end

  def params_identifier
    customer_id
  end

  def revoked?
    revoked_at?
  end

  def revoke!
    touch(:revoked_at) unless revoked?
  end
end
