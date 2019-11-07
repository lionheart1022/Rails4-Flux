module CargofluxCompany
  class << self
    def find!
      Company.find(find_id!)
    end

    def find_id!
      company_ids = Permission.where(permission: Permission::Types::CAN_MANAGE_COMPANIES).pluck(:company_id)

      case company_ids.count
      when 1
        company_ids.first
      when 0
        raise "The special CargoFlux company should be able to manage other companies. It could not be found."
      else
        raise "Only the special CargoFlux company should be able to manage other companies. Found #{company_ids.count}."
      end
    end
  end
end
