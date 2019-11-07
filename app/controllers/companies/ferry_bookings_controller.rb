class Companies::FerryBookingsController < CompaniesController
  include FerryBookingsControllerMethods

  private

  def ferry_booking_new_params
    params.fetch(:ferry_booking, {}).permit(*([:customer_id] + ferry_booking_permitted_attributes))
  end

  def ferry_booking_edit_params
    params.fetch(:ferry_booking, {}).permit(*ferry_booking_permitted_attributes)
  end

  def ferry_booking_permitted_attributes
    [
      :route_id,
      :travel_date,
      :travel_time,
      :truck_type,
      :truck_length,
      :truck_registration_number,
      :trailer_registration_number,
      :with_driver,
      :cargo_weight,
      :empty_cargo,
      :description_of_goods,
      :additional_info,
      :reference,
    ]
  end
end
