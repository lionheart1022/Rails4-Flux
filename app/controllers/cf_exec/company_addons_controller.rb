module CFExec
  class CompanyAddonsController < ExecController
    def create
      @company = Company.find(params[:company_id])

      addon_identifier = params[:addon].try(:[], :identifier)
      @company.enable_addon!(addon_identifier)

      redirect_to exec_company_path(@company)
    end

    def destroy
      @company = Company.find(params[:company_id])

      addon_identifier = params[:addon].try(:[], :identifier)
      @company.disable_addon!(addon_identifier)

      redirect_to exec_company_path(@company)
    end
  end
end
