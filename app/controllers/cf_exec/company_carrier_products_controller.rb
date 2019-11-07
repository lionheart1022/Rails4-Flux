module CFExec
  class CompanyCarrierProductsController < ExecController
    def create
      carrier = Carrier.find(params[:company_carrier_id])

      return redirect_to(exec_company_carrier_path(carrier)) if params[:parent_carrier_product_id].blank?

      parent_carrier = carrier.carrier
      parent_carrier_product = CarrierProduct.where(carrier: parent_carrier).find(params[:parent_carrier_product_id])

      carrier_product = CarrierProduct.find_by(carrier_product_id: parent_carrier_product.id, company_id: carrier.company_id)

      if carrier_product
        carrier_product.is_disabled = false # enable carrier product, it could have been previously disabled
        carrier_product.save!
      else
        CarrierProduct.create_carrier_product_from_existing_product(company_id: carrier.company_id, carrier_id: carrier.id, existing_product_id: parent_carrier_product.id)
      end

      redirect_to exec_company_carrier_path(carrier)
    end

    def destroy
      @carrier = Carrier.find(params[:company_carrier_id])
      @company = @carrier.company
      @carrier_product = @carrier.carrier_products.find(params[:id])
      @child_carrier_products = nil

      ActiveRecord::Base.transaction do
        @child_carrier_products =
          CarrierProduct
          .includes(:company)
          .where(carrier_product_id: @carrier_product)
          .where.not(is_disabled: true)

        @child_carrier_products.load

        if @child_carrier_products.size == 0
          @carrier_product.update!(is_disabled: true)
        end
      end

      if @child_carrier_products.size == 0
        redirect_to exec_company_carrier_path(@carrier)
      else
        render :cannot_destroy
      end
    end
  end
end
