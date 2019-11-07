class Permission < ActiveRecord::Base
  belongs_to :company

  module Types
    CAN_MANAGE_COMPANIES = 'can_manage_companies'
  end
end
