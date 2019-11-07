class EconomicSetting < ActiveRecord::Base
  belongs_to :company
  
  def update_agreement_grant_token(token: nil)
    self.update_attributes!(agreement_grant_token: token)
  end
  
  class << self
    
    def find_for_company(company_id: nil)
      return self.none unless company_id
      self.where(company_id: company_id).first
    end
    
  end
  
end
