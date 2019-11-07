class Companies::CustomerCarrierProductMarginConfigurationsController < CompaniesController
  before_action :set_customer
  before_action :set_carrier_product

  def show
    @table = new_table
    @table.build_rows
  end

  def update
    @table = new_table
    @table.assign_row_params(table_params[:rows])

    if @table.save_rows(current_user: current_user)
      redirect_to url_for(action: "show", zone: params[:zone])
    else
      render :show
    end
  end

  private

  def table_params
    params.fetch(:table, {}).permit(
      :rows => [
        :charge_type,
        :json_weight,
        :margin_amount,
        :interval_margin_amount,
      ]
    )
  end

  def set_current_nav
    @current_nav = "customers"
  end

  def set_customer
    @customer = current_company.customers.find(params[:customer_id])
  end

  def set_carrier_product
    @carrier_product = CarrierProduct.where(company: current_company).find(params[:carrier_product_id])

    @carrier_product_price =
      if @carrier_product.references_price_document?
        @carrier_product.referenced_carrier_product_price
      else
        @carrier_product.carrier_product_price
      end

    if @carrier_product_price.try(:successful?)
      @price_document = @carrier_product_price.price_document
    else
      redirect_to companies_customer_carrier_path(@customer, @carrier_product.carrier), notice: "Could not find valid price document"
    end
  end

  def new_table
    table = CarrierProductMarginConfigurations::PerZoneAndRange::Table.new
    table.price_document = @price_document
    table.selected_zone_index = params[:zone]
    table.customer = @customer
    table.carrier_product = @carrier_product
    table.carrier_product_price = @carrier_product_price

    table
  end
end
