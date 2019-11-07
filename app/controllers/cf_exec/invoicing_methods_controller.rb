module CFExec
  class InvoicingMethodsController < ExecController
    def index
      @invoicing_methods = InvoicingMethods::Base.all.order(:id).includes(:company)
      @addable_companies = Company.where.not(id: InvoicingMethods::Base.all.select(:company_id)).where.not(id: CargofluxCompany.find_id!).order(:id)
    end

    def create
      if params[:company_id].blank?
        redirect_to url_for(action: "index")
        return
      end

      company = Company.find(params[:company_id]) # Ensure it is a valid company

      ActiveRecord::Base.transaction do
        if InvoicingMethods::Base.where(company: company).empty?
          InvoicingMethods::FixedPrice.create!(company: company)
        end
      end

      redirect_to url_for(action: "index")
    end

    def destroy
      invoicing_method = InvoicingMethods::FixedPrice.where(company_id: params[:company_id]).find(params[:id])
      invoicing_method.destroy

      redirect_to url_for(action: "index")
    end

    private

    def active_nav
      [:invoicing, :methods]
    end
  end
end
