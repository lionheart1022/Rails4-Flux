class Companies::PricesController < CompaniesController

  def create
    price_params = params[:advanced_price]
    line_params  = price_params[:advanced_price_line_item]

    shipment_id = params[:shipment_id]
    price_data = {
      cost_price_amount:    line_params[:cost_price_amount],
      cost_price_currency:  price_params[:cost_price_currency],
      sales_price_amount:   line_params[:sales_price_amount],
      sales_price_currency: price_params[:sales_price_currency],
      description:          line_params[:description],
      price_type:           AdvancedPriceLineItem::Types::MANUAL
    }

    interactor = Companies::Prices::AddPrice.new(company_id: current_company.id, shipment_id: shipment_id, price_data: price_data)
    result = interactor.run

    if result.try(:error)
      flash[:error] = result.error
      Rails.logger.debug result.error
      redirect_to redirect_url
    else
      flash[:success] = "Added price"
      redirect_to redirect_url
    end
  end

  def set_sales_price
    line_price_id = params[:id]
    price_params  = params[:advanced_price]
    line_params   = price_params[:advanced_price_line_item]

    shipment_id = params[:shipment_id]
    price_data = {
      cost_price_amount:    line_params[:cost_price_amount],
      cost_price_currency:  price_params[:cost_price_currency],
      sales_price_amount:   line_params[:sales_price_amount],
      sales_price_currency: price_params[:sales_price_currency],
      description:          line_params[:description],
      price_type:           AdvancedPriceLineItem::Types::MANUAL
    }

    interactor = Companies::Prices::SetSalesPrice.new(company_id: current_company.id, line_price_id: line_price_id, shipment_id: shipment_id, price_data: price_data)
    result = interactor.run

    if result.try(:error)
      flash[:error] = result.error
      Rails.logger.debug result.error

      redirect_to redirect_url
    else
      flash[:success] = "Added price"

      redirect_to redirect_url
    end
  end

  def destroy
    line_item_id      = params[:line_item_id]
    shipment_id       = params[:shipment_id]
    advanced_price_id = params[:id]

    line_item = AdvancedPriceLineItem.find_seller_shipment_price_line(
      advanced_price_line_id: line_item_id,
      seller_id: current_company.id,
      seller_type: Company.to_s
    )

    line_item.destroy!
    flash[:success] = "Removed price line"
    redirect_to redirect_url
  end

  private

    def redirect_url
      # Rails.logger.debug params[:rfq]
      shipment = Shipment.find(params[:shipment_id])
      params[:rfq] == 'true' ? companies_shipment_request_path(shipment.shipment_request.id) : companies_shipment_path(shipment.id)
    end

end
