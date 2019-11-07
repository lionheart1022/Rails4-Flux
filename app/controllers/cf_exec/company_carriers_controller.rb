module CFExec
  class CompanyCarriersController < ExecController
    def show
      @carrier = Carrier.find(params[:id])
      @company = @carrier.company

      @view_model = ShowViewModel.new(company: @company, carrier: @carrier)
    end

    def create
      company = Company.find(params[:company_id])

      return redirect_to(exec_company_path(company)) if params[:parent_carrier_id].blank?

      parent_carrier = Carrier.where(carrier_id: nil).find(params[:parent_carrier_id])

      company_carrier = nil

      ActiveRecord::Base.transaction do
        company_carrier = Carrier.find_or_initialize_by(carrier_id: parent_carrier.id, type: parent_carrier.type, company_id: company.id)
        company_carrier.disabled = false # enable carrier, it could have been previously disabled
        company_carrier.save!

        parent_carrier.carrier_products.each do |parent_carrier_product|
          carrier_product = CarrierProduct.find_by(carrier_product_id: parent_carrier_product.id, company_id: company.id)

          if carrier_product
            carrier_product.is_disabled = false # enable carrier product, it could have been previously disabled
            carrier_product.save!
          else
            CarrierProduct.create_carrier_product_from_existing_product(company_id: company.id, carrier_id: company_carrier.id, existing_product_id: parent_carrier_product.id)
          end
        end
      end

      redirect_to exec_company_path(company)
    end

    def destroy
      @carrier = Carrier.find(params[:id])
      @company = @carrier.company
      @buying_companies = nil
      @cannot_destroy = nil

      ActiveRecord::Base.transaction do
        child_carriers =
          Carrier
          .where(carrier_id: @carrier.id)
          .where.not(disabled: true)

        child_carrier_products =
          CarrierProduct
          .where(carrier_product_id: @carrier.carrier_products.select(:id))
          .where.not(is_disabled: true)

        if child_carriers.size > 0 || child_carrier_products.size > 0
          @cannot_destroy = true
          @buying_companies = Company.where(id: child_carriers.map(&:company_id) + child_carrier_products.map(&:company_id))
        else
          @cannot_destroy = false

          @carrier.carrier_products.each do |carrier_product|
            carrier_product.update!(is_disabled: true)
          end

          @carrier.update!(disabled: true)
        end
      end

      if @cannot_destroy
        render :cannot_destroy
      else
        redirect_to exec_company_path(@company)
      end
    end

    private

    def active_nav
      case params[:action]
      when "show"
        [:companies, :show]
      end
    end

    class ShowViewModel
      attr_reader :company
      attr_reader :carrier

      def initialize(company:, carrier:)
        @company = company
        @carrier = carrier
      end

      def enabled_carrier_products
        carrier
          .carrier_products
          .where(carrier_product_id: cf_carrier_products.select(:id))
          .where.not(is_disabled: true)
      end

      def available_carrier_products
        cf_carrier_products
          .where.not(id: enabled_carrier_products.select(:carrier_product_id))
          .where.not(is_disabled: true)
      end

      private

      def cf_carrier_products
        CarrierProduct.where(company: CargofluxCompany.find!, carrier_id: carrier.carrier_id)
      end
    end
  end
end
