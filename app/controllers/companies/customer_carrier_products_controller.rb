class Companies::CustomerCarrierProductsController < CompaniesController
  def update
    customer = current_company.customers.find(params[:customer_id])
    carrier_product = current_company.carrier_products.find(params[:id])
    customer_carrier_product = nil

    ActiveRecord::Base.transaction do
      customer_carrier_product = CustomerCarrierProduct.find_or_initialize_by(customer: customer, carrier_product: carrier_product)
      customer_carrier_product.assign_attributes(customer_carrier_product_params)

      if customer_carrier_product.persisted? && customer_carrier_product.is_disabled?
        customer_carrier_product.assign_attributes(enable_autobooking: false, automatically_autobook: false, allow_auto_pickup: false)
      end

      if customer_carrier_product.is_enabled? || customer_carrier_product.persisted?
        customer_carrier_product.save!
      end
    end

    if customer_carrier_product.is_enabled? && customer_carrier_product.sales_price.use_margin_config?
      redirect_to companies_customer_carrier_product_margin_configuration_path(customer_carrier_product.customer, customer_carrier_product.carrier_product)
    else
      redirect_to params[:redirect_url] || companies_customer_carriers_path(customer_carrier_product.customer), notice: "Changes were saved"
    end
  end

  private

  def customer_carrier_product_params
    params.fetch(:customer_carrier_product, {}).permit(
      :is_enabled,
      :is_disabled,
      :enable_autobooking,
      :automatically_autobook,
      :allow_auto_pickup,
      :margin_percentage,
      :margin_type,
      :test,
    )
  end
end
