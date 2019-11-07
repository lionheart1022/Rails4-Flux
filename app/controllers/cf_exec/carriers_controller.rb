module CFExec
  class CarriersController < ExecController
    helper_method :available_companies_for_select

    def index
      @carriers = available_carriers.order(:id).page(params[:page])
    end

    def show
      @carrier = available_carriers.find(params[:id])
      @carrier_products = @carrier.carrier_products.where.not(is_disabled: true).order(:id)
    end

    def new_copy
      @carrier = available_carriers.find(params[:id])

      @carrier_copy = @carrier.dup
      @carrier_products = @carrier.carrier_products.where.not(is_disabled: true).order(:id)
      @carrier_products_copy = @carrier_products.map(&:dup)
    end

    def create_copy
      @carrier = available_carriers.find(params[:id])

      duplication = CarrierDuplication.new(@carrier, copy_params: carrier_copy_params)
      duplication.create_copy!

      if duplication.success?
        if duplication.carrier_copy.company == CargofluxCompany.find!
          redirect_to url_for(action: "show", id: duplication.carrier_copy.id)
        else
          redirect_to url_for(action: "index")
        end
      else
        @carrier_products_copy = duplication.carrier_products_copy
        @carrier_copy = duplication.carrier_copy
        @carrier_products = duplication.carrier_products_to_a

        render :new_copy
      end
    end

    private

    def available_carriers
      Carrier.where(company: CargofluxCompany.find!)
    end

    def available_companies_for_select
      Company.all.order(:name).where.not(id: CargofluxCompany.find_id!)
    end

    def carrier_copy_params
      params.require(:carrier_copy).permit(
        :name,
        :company_id,
        :products => [
          :original_product_id,
          :name,
          :product_code,
        ]
      )
    end

    def active_nav
      case params[:action]
      when "index"
        [:carriers, :index]
      when "show"
        [:carriers, :show]
      when "new_copy", "create_copy"
        [:carriers, :copy]
      end
    end
  end
end
