class FerryBooking < ActiveRecord::Base
  scope :waiting_for_response, -> { where(waiting_for_response: true) }
  scope :editable, -> { where(waiting_for_response: false, transfer_in_progress: false) }

  belongs_to :shipment, required: true
  belongs_to :route, class_name: "FerryRoute", required: true
  belongs_to :product, class_name: "FerryProduct", required: true
  has_many :events, class_name: "FerryBookingEvent", as: :eventable
  has_many :requests, class_name: "FerryBookingRequest"
  has_many :responses, class_name: "FerryBookingResponse"

  class << self
    def human_friendly_truck_type(truck_type)
      case truck_type
      when "cargo_car"
        "Cargo Car"
      when "lorry"
        "Lorry"
      when "lorry_and_trailer"
        "Lorry (+ Trailer)"
      when "trailer"
        "Trailer"
      end
    end

    def cancel_shipment(shipment, context:)
      transaction do
        ferry_booking = find_by_shipment_id!(shipment.id)
        ferry_booking.register_cancel!(initiator: context.initiator)
      end

      true
    end
  end

  def requests_to_handle
    requests.unhandled.order(:id)
  end

  def save_and_register_create!(args = {})
    self.transfer_in_progress = true
    save!

    event = events.new_booking_created_event(current_state_hash: current_state_hash)
    event.assign_attributes(args.slice(:initiator))
    event.save!

    requests.new_create_request.save_and_enqueue_job!

    true
  end

  def save_and_register_update!(args = {})
    self.transfer_in_progress = true

    state_hash_before = current_state_hash # Record before-state
    update!(args.fetch(:ferry_booking_attributes))
    shipment.update!(args.fetch(:shipment_attributes))
    state_hash_after = current_state_hash # Record after-state

    event = events.new_booking_updated_event(previous_state_hash: state_hash_before, current_state_hash: state_hash_after)
    event.assign_attributes(args.slice(:initiator))
    event.save!

    if shipment.awb.present?
      requests.new_update_request.save_and_enqueue_job!
    else
      requests.new_create_request.save_and_enqueue_job!
    end

    true
  end

  def check_and_register_updated_time_of_departure!(traveltime_hhmmss:, initiator_label: "EDI integration")
    return if traveltime_hhmmss.blank?

    new_time_of_departure = "#{traveltime_hhmmss[0..1]}:#{traveltime_hhmmss[2..3]}"

    # No change in time of departure - great, we don't need to do anything!
    return if product.time_of_departure == new_time_of_departure

    new_product =
      FerryProduct
      .active
      .joins(:route)
      .where(route_id: route_id, time_of_departure: new_time_of_departure)
      .first

    if new_product
      state_hash_before = current_state_hash # Record before-state
      update!(product: new_product)
      state_hash_after = current_state_hash # Record after-state

      event = events.new_booking_updated_event(previous_state_hash: state_hash_before, current_state_hash: state_hash_after)
      event.custom_initiator_label = initiator_label
      event.description = "Time of departure has been updated to #{new_time_of_departure}"
      event.save!
    else
      events.create!(
        label: "booking_updated",
        custom_initiator_label: initiator_label,
        description: "Time of departure has changed to #{new_time_of_departure} but no product with this time could be found",
      )
    end

    true
  end

  def register_cancel!(args)
    if shipment.awb?
      self.transfer_in_progress = true
      save!
    end

    shipment.update!(state: Shipment::States::CANCELLED)
    events.new_booking_cancelled_event(args.slice(:initiator)).save!
    requests.new_cancel_request.save_and_enqueue_job! if shipment.awb?
  end

  def editable?
    !uneditable?
  end

  def uneditable?
    in_progress? || cancelled?
  end

  def in_progress?
    transfer_in_progress? || waiting_for_response?
  end

  def cancelled?
    [Shipment::States::CANCELLED].include?(shipment.state)
  end

  def carrier_product
    if product
      product.carrier_product
    end
  end

  def time_of_departure
    if product
      product.time_of_departure
    end
  end

  def additional_info_line_1
    additional_info_lines[0]
  end

  def additional_info_line_2
    additional_info_lines[1]
  end

  def additional_info_lines
    additional_info.to_s.lines.reject(&:blank?)
  end

  def current_state_hash
    validate!

    {
      "route_id" => route_id,
      "travel_date" => shipment.shipping_date,
      "travel_time" => product.time_of_departure,
      "truck_type" => truck_type,
      "truck_length" => truck_length,
      "truck_registration_number" => truck_registration_number,
      "trailer_registration_number" => trailer_registration_number,
      "with_driver" => with_driver,
      "cargo_weight" => cargo_weight,
      "empty_cargo" => empty_cargo,
      "description_of_goods" => description_of_goods,
      "additional_info" => additional_info,
      "reference" => shipment.reference,
    }
  end

  def sftp_download_response!
    company = product.route.company
    integration = product.integration

    FerryBookingDownload.sftp_download_and_save!(
      company: company,
      host: integration.sftp_host,
      user: integration.sftp_user,
      password: integration.sftp_password,
      pattern: "CONF4*/*.xml",
    )
  end
end
