module CFApp
  class ContactImportsController < BaseAppController
    def index
      render_new_page
    end

    def new
      render_new_page
    end

    def create
      case params[:state]
      when "show_parsed"
        if params[:import].try(:[], :file).blank?
          redirect_to url_for(action: "new")
          return
        end

        @import = ContactImport.from_xlsx_file(params[:import][:file])
        @import.perform!

        render :show_parsed
      when "bulk_create"
        import_params = params.fetch(:import, {}).permit(
          :rows => [
            :company_name,
            :attention,
            :address_1,
            :address_2,
            :address_3,
            :zip_code,
            :city,
            :country_code,
            :state_code,
            :phone,
            :email,
          ]
        )

        ContactImport.bulk_create(
          import_params,
          company: params[:app_scope] == "companies" ? current_company : nil,
          customer: params[:app_scope] == "customers" ? current_customer : nil,
        )

        flash[:success] = "Import completed"
        redirect_to url_for(action: "new")
      else
        redirect_to url_for(action: "new")
      end
    end

    private

    def render_new_page
      render :new
    end

    def set_current_nav
      @current_nav = "contacts"
    end
  end
end
