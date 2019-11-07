class Companies::CarriersController < CompaniesController
  def index
    @carriers =
      ::Carrier
      .find_enabled_company_carriers(company_id: current_company.id)
      .includes(:carrier)
      .sort { |a, b|
        if a.owner_carrier.company_id == b.owner_carrier.company_id
          a.name.to_s.strip.casecmp(b.name.to_s.strip)
        else
          a.owner_carrier.company_id <=> b.owner_carrier.company_id
        end
      }
  end

  def new
    @carrier = Carrier.new
  end

  def create
    @carrier = Carrier.new(company: current_company)
    @carrier.assign_attributes(params.require(:carrier).permit(:name))

    if @carrier.save
      redirect_to new_companies_carrier_product_path(@carrier), notice: "'#{@carrier.name}' is ready! Now you can create your first product for this carrier."
    else
      render :new
    end
  end

  def show
    @carrier =
      ::Carrier
      .find_enabled_company_carriers(company_id: current_company.id)
      .find(params[:id])

    @carrier_products =
      ::CarrierProduct
      .includes(:rules)
      .find_enabled_company_carrier_products(company_id: current_company.id, carrier_id: @carrier.id)
      .sort_by { |p| p.name.downcase }
  end

  def edit
    @carrier =
      ::Carrier
      .find_company_carrier(company_id: current_company.id, carrier_id: params[:id])

    raise "Cannot edit locked carrier" if @carrier.is_locked_for_editing?
  end

  def update
    @carrier =
      ::Carrier
      .find_company_carrier(company_id: current_company.id, carrier_id: params[:id])

    raise "Cannot edit locked carrier" if @carrier.is_locked_for_editing?

    @carrier.assign_attributes(params.require(:carrier).permit(:name))

    if @carrier.save
      redirect_to url_for(action: "show")
    else
      render :edit
    end
  end

  def bulk_update
    carrier =
      ::Carrier
      .find_enabled_company_carriers(company_id: current_company.id)
      .find(params[:id])

    carrier_products =
      ::CarrierProduct
      .find_enabled_company_carrier_products(company_id: current_company.id, carrier_id: carrier.id)

    carrier_products_attributes = params.fetch(:carrier, {}).permit(
      :carrier_products => [
        :id,
        :automatic_tracking,
      ]
    )

    begin
      CarrierProduct.transaction do
        carrier_products_attributes[:carrier_products].each do |_, product_attrs|
          carrier_product = carrier_products.find(product_attrs[:id])
          carrier_product.automatic_tracking = product_attrs[:automatic_tracking] if product_attrs[:automatic_tracking].present?
          carrier_product.save!
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = "The carrier product '#{e.record.name}' could not be updated: #{e.record.errors.full_messages.to_sentence}"
    else
      flash[:success] = "Saved changes to automatic tracking"
    end

    redirect_to url_for(action: "show")
  end

  private

  def set_current_nav
    @current_nav = "carriers"
  end
end
