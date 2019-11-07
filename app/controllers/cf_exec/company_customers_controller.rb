module CFExec
  class CompanyCustomersController < ExecController
    def create
      company = Company.find(params[:company_id])

      if params[:customer].try(:[], :recording_type) == "Company" && params[:customer].try(:[], :recording_id).present?
        customer = Company.find(params[:customer].try(:[], :recording_id))
        company.add_carrier_product_customer!(customer)
      end

      redirect_to exec_company_path(company)
    end
  end
end
