class Companies::PriceDocuments::CarrierProductsController < CompaniesController
  def show
    carrier_product = CarrierProduct.where(company: current_company).find(params[:id])
    carrier_product_price = carrier_product.carrier_product_price

    if carrier_product_price.nil?
      redirect_to url_for(controller: "carriers", action: "show", id: carrier_product.carrier_id)
      return
    end

    @view_model = Companies::CarrierProductPrices::ShowView.new(carrier_product_price: carrier_product_price)
  end

  def update
    carrier_product = CarrierProduct.where(company: current_company).find(params[:id])

    if params[:file].blank?
      redirect_to url_for(controller: "carriers", action: "show", id: carrier_product.carrier_id)
      return
    end

    ActiveRecord::Base.transaction do
      upload = PriceDocumentUpload.new
      upload.company = current_company
      upload.carrier_product = carrier_product
      upload.created_by = current_user
      upload.attach_file(params[:file])
      upload.active = true
      upload.save!

      upload.inactivate_other_uploads!

      carrier_product.upload_carrier_product_price!(file: params[:file])
    end

    if carrier_product.carrier_product_price.parsed_without_warnings?
      flash[:success] = "Successfully parsed price document"
      redirect_to url_for(controller: "carriers", action: "show", id: carrier_product.carrier_id)
      return
    end

    if carrier_product.carrier_product_price.parsed_with_warnings?
      flash[:notice] = "Successfully parsed price document, but warnings are present"
    else
      flash[:error] = "An error occurred and the price document was not parsed"
    end

    redirect_to url_for(controller: "carrier_products", action: "show", id: carrier_product.id)
  end

  def destroy
    carrier_product = CarrierProduct.where(company: current_company).find(params[:id])

    ActiveRecord::Base.transaction do
      PriceDocumentUpload
        .active
        .where(company: current_company)
        .where(carrier_product: carrier_product)
        .update_all(active: false)

      CarrierProductPrice
        .where(carrier_product: carrier_product)
        .each(&:destroy!)
    end

    redirect_to url_for(controller: "carriers", action: "show", id: carrier_product.carrier_id)
  end

  def redirect_to_download_url
    carrier_product = CarrierProduct.where(company: current_company).find(params[:id])
    upload =
      PriceDocumentUpload
      .active
      .where(company: current_company)
      .where(carrier_product: carrier_product)
      .first

    download_uri = upload.generate_download_url if upload

    redirect_to download_uri.to_s.presence || url_for(controller: "carriers", action: "show", id: carrier_product.carrier_id)
  end

  private

  def set_current_nav
    @current_nav = "price_documents"
  end
end
