class FerryBookingRequest < ActiveRecord::Base
  MAX_FAILURE_COUNT = 5
  AVAILABLE_CHANGES = %w(
    create
    update
    cancel
  )

  belongs_to :ferry_booking, required: true
  belongs_to :event, required: false, class_name: "FerryBookingEvent"
  belongs_to :upload, required: false, class_name: "FerryBookingUpload"

  scope :unhandled, -> { where(completed_at: nil) }
  scope :handled, -> { where.not(completed_at: nil) }
  scope :unhandled_and_older_than, ->(date) { unhandled.where(arel_table[:created_at].lt(date)) }

  validates :change, inclusion: { in: AVAILABLE_CHANGES }

  class << self
    def last_handled_request
      handled.order(id: :desc).first
    end

    def new_create_request(args = {})
      new(args) do |request|
        request.change = "create"
      end
    end

    def new_update_request(args = {})
      new(args) do |request|
        request.change = "update"
      end
    end

    def new_cancel_request(args = {})
      new(args) do |request|
        request.change = "cancel"
      end
    end
  end

  def save_and_enqueue_job!
    save!
    FerryBookingRequestJob.perform_later(ferry_booking_id)
  end

  def completed?
    completed_at.present?
  end

  def build_ref
    prefix =
      if Rails.env.development?
        "CF-D-#{ENV.fetch('FERRY_BOOKING_PREFIX') { ENV.fetch('USER') }.slice(0, 5)}"
      elsif Rails.env.production?
        "CF-P"
      elsif Rails.env.staging?
        "CF-S"
      end

    "#{prefix}_#{ferry_booking.shipment.id.to_s}"
  end

  def handle_with_lock!
    with_lock { handle_without_lock! }
  end

  def handle_without_lock!
    return if completed?

    self.ref = build_ref

    scl_booking = ScandlinesBookingRequest.build_from_ferry_booking(ferry_booking, ref: ref, change: change)
    scl_edi_xml = scl_booking.to_edi_xml
    file_name = "#{ref}__#{SecureRandom.hex(3)}.xml"
    file_path = "./BOOK4SCL/#{file_name}"

    build_upload(company: ferry_booking.product.route.company, file_path: file_path, document: scl_edi_xml)

    begin
      upload.sftp_upload!(
        host: ferry_booking.product.integration.sftp_host,
        user: ferry_booking.product.integration.sftp_user,
        password: ferry_booking.product.integration.sftp_password,
      )
    rescue Net::SFTP::StatusException => e
      register_delivery_failure!(description: "Could not deliver EDI document to Scandlines")
      ExceptionMonitoring.report_exception(e, context: { ferry_booking_id: ferry_booking_id })
      return
    rescue SocketError => e
      register_delivery_failure!(description: "Could not deliver EDI document to Scandlines due to connection issues")
      ExceptionMonitoring.report_exception(e, context: { ferry_booking_id: ferry_booking_id })
      return
    rescue => e
      register_delivery_failure!(description: "Could not deliver EDI document to Scandlines due to unknown issues - please notify an administrator")
      ExceptionMonitoring.report_exception!(e, context: { ferry_booking_id: ferry_booking_id })
      return
    end

    upload.save!

    register_delivery_success!(description: "Successfully delivered EDI document to Scandlines")

    self.completed_at = Time.now
    self.save!

    FerryBookingDownloadJob.set(wait: 5.minutes).perform_later(ferry_booking.id)
  end

  def create_confirm_success_event!(description:, initiator_label: "EDI integration")
    case change
    when "create", "update"
      ferry_booking.events.create!(label: "booking_confirmed", custom_initiator_label: initiator_label, description: description)
    when "cancel"
      ferry_booking.events.create!(label: "booking_cancellation_confirmed", custom_initiator_label: initiator_label, description: description)
    end
  end

  def register_confirm_success!(waybill: nil, additional_info: nil)
    case change
    when "create", "update"
      ferry_booking.update!(additional_info_from_response: additional_info.presence)
      ferry_booking.shipment.book(awb: waybill)
      FerryBookingEventManager.handle_event(event: Shipment::Events::BOOK, event_arguments: { shipment_id: ferry_booking.shipment_id })
    when "cancel"
      ferry_booking.shipment.cancel
      FerryBookingEventManager.handle_event(event: Shipment::Events::CANCEL, event_arguments: { shipment_id: ferry_booking.shipment_id })
    end
  end

  def create_confirm_failure_event!(description:, initiator_label: "EDI integration")
    event = nil

    case change
    when "create", "update"
      ferry_booking.shipment.report_problem(comment: description)
      event = ferry_booking.events.create!(label: "booking_failed", custom_initiator_label: initiator_label, description: description)
    when "cancel"
      ferry_booking.shipment.report_problem(comment: description)
      event = ferry_booking.events.create!(label: "booking_cancellation_failed", custom_initiator_label: initiator_label, description: description)
    end

    FerryBookingEventManager.handle_event(event: Shipment::Events::REPORT_PROBLEM, event_arguments: { shipment_id: ferry_booking.shipment_id })

    event
  end

  def register_confirm_failure!
    ferry_booking.shipment.update!(state: Shipment::States::BOOKING_FAILED)
  end

  private

  def register_delivery_success!(description:, initiator_label: "EDI integration")
    case change
    when "create", "update"
      ferry_booking.events.create!(label: "booking_delivered", custom_initiator_label: initiator_label, description: description)
      ferry_booking.shipment.update!(state: Shipment::States::BOOKING_INITIATED)
    when "cancel"
      ferry_booking.events.create!(label: "booking_cancellation_delivered", custom_initiator_label: initiator_label, description: description)
    end

    ferry_booking.update!(transfer_in_progress: false, waiting_for_response: true)
  end

  def register_delivery_failure!(description:, initiator_label: "EDI integration")
    case change
    when "create", "update"
      ferry_booking.events.create!(label: "booking_delivery_failed", custom_initiator_label: initiator_label, description: description)
    when "cancel"
      ferry_booking.events.create!(label: "booking_cancellation_delivery_failed", custom_initiator_label: initiator_label, description: description)
    end

    ferry_booking.shipment.update!(state: Shipment::States::BOOKING_FAILED)

    self.failure_count += 1

    if failure_count >= MAX_FAILURE_COUNT
      self.completed_at = Time.now
      ferry_booking.update!(transfer_in_progress: false, waiting_for_response: false)
    end

    save!
  end
end
