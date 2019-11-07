class Customers::FerryBookingsController < CustomersController
  include FerryBookingsControllerMethods

  private

  def ferry_booking_new_params
    ferry_booking_params
  end

  def ferry_booking_edit_params
    ferry_booking_params
  end

  def ferry_booking_params
    params.fetch(:ferry_booking, {}).permit(
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
    )
  end
end
