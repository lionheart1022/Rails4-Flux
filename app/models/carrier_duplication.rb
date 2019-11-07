class CarrierDuplication
  attr_reader :carrier
  attr_reader :carrier_copy
  attr_reader :carrier_products_copy

  def initialize(carrier, copy_params:)
    @carrier = carrier
    @copy_params = copy_params
  end

  def create_copy!
    @carrier_products_copy = build_carrier_products_copy!
    @carrier_copy = carrier.dup

    carrier_copy.assign_attributes(
      name: copy_params[:name],
      company_id: copy_to_company_id,
    )

    @copy_status = :ok

    ActiveRecord::Base.transaction do
      begin
        carrier_copy.save!
      rescue ActiveRecord::RecordInvalid
        @copy_status = :invalid
        return # Exit early as the carrier is required for the carrier product
      end

      carrier_products_copy.each do |carrier_product_copy|
        carrier_product_copy.carrier = carrier_copy
        carrier_product_copy.company_id = copy_to_company_id

        begin
          carrier_product_copy.save!
        rescue ActiveRecord::RecordInvalid
          @copy_status = :invalid
        end
      end

      raise ActiveRecord::Rollback, "Data is not fully valid, roll back" if @copy_status == :invalid
    end

    true
  end

  def success?
    @copy_status == :ok
  end

  def build_carrier_products_copy!
    copy_params[:products].map do |index_key, product_params|
      original_carrier_product = carrier_products_to_a.fetch(Integer(index_key))

      if String(product_params[:original_product_id]) == String(original_carrier_product.id)
        copy = original_carrier_product.dup
        copy.assign_attributes(
          name: product_params[:name].presence,
          product_code: product_params[:product_code].presence,
        )
        copy
      else
        nil
      end
    end
  end

  def carrier_products_to_a
    @_carrier_products_relation ||= carrier.carrier_products.where.not(is_disabled: true).order(:id).to_a
  end

  private

  attr_reader :copy_params

  def copy_to_company_id
    if copy_params[:company_id].present?
      copy_params[:company_id]
    else
      carrier.company_id
    end
  end
end
