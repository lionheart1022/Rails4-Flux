class CarrierProductAutobookRequest < ActiveRecord::Base

  module States
    CREATED     = 'created'
    WAITING     = 'waiting'
    IN_PROGRESS = 'in_progress'
    ERROR       = 'error'
    COMPLETED   = 'completed'
  end

  module Events
    CREATE    = 'events_carrier_product_autobook_request_create'
    ENQUEUED  = 'events_carrier_product_autobook_request_enqueued'
    STARTED   = 'events_carrier_product_autobook_request_started'
    ERROR     = 'events_carrier_product_autobook_request_error'
    COMPLETED = 'events_carrier_product_autobook_request_completed'
  end

  module AutoBooking
    QUEUE_NAME     = 'booking'
  end

  has_many    :events, as: :reference
  belongs_to  :shipment
  belongs_to  :company
  belongs_to  :customer

  serialize :data, Hash

  # PUBLIC API
  class << self
    def create_carrier_product_autobook_request(company_id: nil, customer_id: nil, shipment_id: nil)
      # create request
      request = nil
      CarrierProductAutobookRequest.transaction do
        request = self.create!({
          company_id:   company_id,
          customer_id:  customer_id,
          shipment_id:  shipment_id,
          uuid:         SecureRandom.hex(3),
          state:        CarrierProductAutobookRequest::States::CREATED,
        })
      end

      # log change
      event_data = {
        reference_id:   request.id,
        reference_type: request.class.to_s,
        event_type:     CarrierProductAutobookRequest::Events::CREATE,
      }
      request.events << Event.create_event(company_id: company_id, customer_id: customer_id, event_data: event_data)

      return request
    end

    def create_carrier_product_autobook_request_and_enqueue_job(company_id: nil, customer_id: nil, shipment_id: nil)
      CarrierProductAutobookRequest.transaction do
        request = self.create_carrier_product_autobook_request(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
        request.enqueue_autobook_job
      end
    end

    # Finders

    # @return [CarrierProductAutobookRequest]
    def find_company_requests(company_id: nil)
      self.where(company_id: company_id)
    end

    # @return [CarrierProductAutobookRequest]
    def find_customer_requests(customer_id: nil)
      self.where(customer_id: customer_id)
    end

    # @return [CarrierProductAutobookRequest]
    def find_requests_in_state(state: nil)
      self.where(state: state)
    end

    # @return [CarrierProductAutobookRequest]
    def find_company_request(company_id: nil, request_id: nil)
      self.where(company_id: company_id).where(id: request_id).first
    end

    # A shipment can have previous autobook requests that have failed, so always use the most recent
    #
    # @return [CarrierProductAutobookRequest]
    def find_request_for_shipment(company_id: nil, shipment_id: nil)
      self.where(company_id: company_id).where(shipment_id: shipment_id).order(:created_at).last
    end
  end

  # INSTANCE PUBLIC API

  # Returns the default background job queue name (TNT has its own)
  def auto_book_queue_name
    CarrierProductAutobookRequest::AutoBooking::QUEUE_NAME
  end

  def completed?
    self.state == States::COMPLETED
  end

  def error?
    self.state == States::ERROR
  end

  def enqueue_autobook_job
    CarrierProductAutobookRequest.transaction do
      self.update_state(state: CarrierProductAutobookRequest::States::WAITING, event: CarrierProductAutobookRequest::Events::ENQUEUED)
      # Start booking on async queue
      job = AutobookShipmentDelayedJob.new(customer_id: self.customer_id, shipment_id: self.shipment_id, carrier_product_autobook_request_id: self.id)
      Delayed::Job.enqueue(job, :queue => self.auto_book_queue_name)
    end
  end

  def enqueue_retry_awb_document_job
    CarrierProductAutobookRequest.transaction do
      # Get AWB document on async queue
      job = ::RetryAwbDocumentDelayedJob.new(customer_id: self.customer_id, shipment_id: self.shipment_id, carrier_product_autobook_request_id: self.id)
      Delayed::Job.enqueue(job, :queue => self.auto_book_queue_name)
    end
  end

  def enqueue_retry_consignment_note_job
    CarrierProductAutobookRequest.transaction do
      # Get consignment document on async queue
      job = ::RetryConsignmentNoteDelayedJob.new(customer_id: self.customer_id, shipment_id: self.shipment_id, carrier_product_autobook_request_id: self.id)
      Delayed::Job.enqueue(job, :queue => self.auto_book_queue_name)
    end
  end

  def started
    self.update_state(state: CarrierProductAutobookRequest::States::IN_PROGRESS, event: CarrierProductAutobookRequest::Events::STARTED, info: nil)
  end

  def completed
    self.update_state(state: CarrierProductAutobookRequest::States::COMPLETED, event: CarrierProductAutobookRequest::Events::COMPLETED, info: nil)
  end

  def error(exception: nil, info: nil)
    self.update_state(state: CarrierProductAutobookRequest::States::ERROR, event: CarrierProductAutobookRequest::Events::ERROR, info: info)
  end

  def update_state(state: nil, event: nil, info: nil)
    CarrierProductAutobookRequest.transaction do
      self.update_attributes({
        state:  state,
        info:   info,
      })

      # log change
      event_data = {
        reference_id:   self.id,
        reference_type: self.class.to_s,
        event_type:     event,
      }
      self.events << Event.create_event(company_id: self.company_id, customer_id: self.customer_id, event_data: event_data)

      return self
    end
  end

  def autobook_shipment
    raise StandardError.new, "Abstract class. Not implemented"
  end

  def retry_awb_document
    raise StandardError.new, "Abstract class. Not implemented"
  end

  def handle_error(exception: nil)
    Rails.logger.info "Handling exception...\n#{exception.inspect}"
    case exception.class.to_s

    when BookingLib::Errors::RuntimeException.to_s
      Rails.logger.error(exception.error_code)
      Rails.logger.error(exception.errors)

      self.error(exception: exception, info: exception.human_friendly_text)

      shipment = Shipment.find(self.shipment_id)
      shipment.booking_fail(comment: 'Booking failed, a runtime error occured', linked_object: self)
      EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_AWB_PROBLEM, event_arguments: {shipment_id: shipment.id})


    when BookingLib::Errors::BookingFailedException.to_s
      Rails.logger.error(exception.error_code)
      Rails.logger.error(exception.errors)

      # set error state on request
      self.error(exception: exception, info: exception.human_friendly_text)
      # hook to allow special handling of exception
      handle_booking_failed_exception(exception)

      # transform errors to shipment errors
      shipment_errors = exception.try(:errors).try(:map) do |error|
        Shipment::Errors::GenericError.new(code: error.code, description: error.description)
      end

      # save errors on shipment and send email notifications
      shipment = Shipment.find(self.shipment_id)
      shipment.booking_fail(comment:'Automatic booking failed', errors: shipment_errors, linked_object: self)
      EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_PROBLEM, event_arguments: {shipment_id: shipment.id})

    when BookingLib::Errors::AwbDocumentFailedException.to_s
      Rails.logger.error(exception.error_code)
      Rails.logger.error(exception.errors)

      # set error state on request
      self.error(exception: exception, info: exception.human_friendly_text)
      # hook to allow special handling of exception
      handle_awb_exceptions(exception)

      # set error on shipment and send email notifications
      shipment = Shipment.find(self.shipment_id)
      shipment.book_without_awb_document(awb: shipment.awb, comment: 'Adding AWB document failed', linked_object: self)
      EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_AWB_PROBLEM, event_arguments: {shipment_id: shipment.id})

    when Shipment::Errors::CreateAwbAssetException.to_s
      Rails.logger.error(exception)

      self.error(exception: exception, info: exception)

      shipment = Shipment.find(self.shipment_id)
      shipment.book_without_awb_document(awb: shipment.awb, comment: 'Adding AWB document failed', linked_object: self)
      EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_AWB_PROBLEM, event_arguments: {shipment_id: shipment.id})

    when BookingLib::Errors::ConsignmentNoteFailedException.to_s
      Rails.logger.error(exception.error_code)
      Rails.logger.error(exception.errors)

      # set error state on request
      self.error(exception: exception, info: exception.human_friendly_text)
      # hook to allow special handling of exception
      handle_consignment_exceptions(exception)

      # set error on shipment and send email notifications
      shipment = Shipment.find(self.shipment_id)
      shipment.book_without_consignment_note(awb: shipment.awb, comment: 'Adding consignment note failed', linked_object: self)
      EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_CONSIGNMENT_NOTE_PROBLEM, event_arguments: {shipment_id: shipment.id})

    when Shipment::Errors::CreateConsignmentNoteAssetException.to_s
      Rails.logger.error(exception)

      self.error(exception: exception, info: exception)

      shipment = Shipment.find(self.shipment_id)
      shipment.book_without_awb_document(awb: shipment.awb, comment: 'Adding consignment note failed', linked_object: self)
      EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_CONSIGNMENT_NOTE_PROBLEM, event_arguments: {shipment_id: shipment.id})

    when BookingLib::Errors::BookingLibException.to_s
      Rails.logger.error(exception.error_code)
      Rails.logger.error(exception.errors)

      # set error on shipment and send email notifications
      self.error(exception: exception, info: exception.human_friendly_text)
      shipment = Shipment.find(self.shipment_id)
      shipment.booking_fail(comment:'An unknown error occured while performing automatic booking', linked_object: self)
      EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_PROBLEM, event_arguments: {shipment_id: shipment.id})

    else
      # set error on shipment and send email notifications
      Rails.logger.error("UnknownError: #{exception}")
      self.error(exception: exception, info: exception.message)
      shipment = Shipment.find(self.shipment_id)
      shipment.booking_fail(comment:'An unknown error occured while performing automatic booking', linked_object: self)
      EventManager.handle_event(event: Shipment::Events::REPORT_AUTOBOOK_PROBLEM, event_arguments: {shipment_id: shipment.id})
    end
  rescue => e
    self.error(exception: e, info: e.message)
    ExceptionMonitoring.report(e)
    Rails.logger.error(e)
    raise e
  end

  def handle_consignment_exceptions(exception)
    # Does nothing - override in subclass
  end

  def handle_awb_exceptions(exception)
    # Does nothing - override in subclass
  end

  def handle_booking_failed_exception(exception)
    # Does nothing - override in subclass
  end
end
