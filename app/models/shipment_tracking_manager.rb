class ShipmentTrackingManager
  LOG_TAG = "ShipmentTrackingManager".freeze

  class << self
    def track(shipments: nil, shipments_eligible_for_tracking: nil)
      shipments =
        if shipments_eligible_for_tracking
          shipments_eligible_for_tracking
        else
          (shipments || Shipment.all).find_shipments_eligible_for_tracking
        end

      shipments = shipments.includes(:carrier_product)

      Rails.logger.tagged(LOG_TAG) { |logger| logger.info "TrackShipmentsInit total_shipments=#{shipments.length}" }

      tms_total = Benchmark.measure do
        shipments.each do |shipment|
          Raven.extra_context(shipment_id: shipment.id)

          tms_single_shipment = Benchmark.measure do
            new(shipment).track
          end

          Raven::Context.clear!

          Rails.logger.tagged(LOG_TAG) { |logger| logger.info sprintf("TrackShipmentBenchmark process_time_in_seconds=%.2f", tms_single_shipment.real) }
        end
      end

      Rails.logger.tagged(LOG_TAG) { |logger| logger.info sprintf("TrackShipmentsEnd total_process_time_in_seconds=%.2f", tms_total.real) }
    end
  end

  attr_accessor :shipment
  attr_reader :trackings

  def initialize(shipment)
    self.shipment = shipment
    self.trackings = []
  end

  def fetch_trackings!
    self.trackings = shipment.carrier_product.track_shipment(shipment: shipment)
    @_trackings_fetched = true
  end

  def trackings_fetched?
    @_trackings_fetched
  end

  def track
    fetch_trackings! unless trackings_fetched?

    track_shipment
  rescue => e
    ExceptionMonitoring.report(e, context: { shipment_id: shipment.id })
  end

  private

  attr_writer :trackings

  def track_shipment
    return nil if trackings.blank?

    ordered_trackings = trackings.sort_by(&:event_time)

    Tracking.transaction do
      ordered_trackings.each do |tracking|
        log_params = "company_id=#{shipment.company_id} company_name='#{shipment.company.name}' shipment=#{shipment.unique_shipment_id} shipment_state=#{shipment.state} tracking_status=#{tracking.status.inspect}"

        already_reported = Tracking.already_reported?(shipment_id: shipment.id, event_time: tracking.event_time)
        Rails.logger.tagged(LOG_TAG) { |logger| logger.info "TrackingAlreadyReported OK #{log_params} already_reported=#{already_reported.inspect}" }

        next if already_reported

        should_change_state = Tracking.should_change_state?(shipment_id: shipment.id, status: tracking.status)
        Rails.logger.tagged(LOG_TAG) { |logger| logger.info "TrackingShouldChangeState OK #{log_params} should_change_state=#{should_change_state.inspect}" }

        tracking.save!

        change_state_to =
          if should_change_state
            case tracking.status
            when TrackingLib::States::IN_TRANSIT then :in_transit
            when TrackingLib::States::DELIVERED then :delivered
            when TrackingLib::States::EXCEPTION then :failed
            end
          end

        case change_state_to
        when :in_transit
          shipment.ship(comment: tracking.description, linked_object: tracking)
          EventManager.handle_event(event: Shipment::Events::SHIP, event_arguments: { shipment_id: shipment.id })
        when :delivered
          shipment.delivered_at_destination(comment: tracking.description, linked_object: tracking)
          EventManager.handle_event(event: Shipment::Events::DELIVERED_AT_DESTINATION, event_arguments: { shipment_id: shipment.id })
        when :failed
          shipment.report_problem(comment: tracking.description, linked_object: tracking)
          EventManager.handle_event(event: Shipment::Events::REPORT_PROBLEM, event_arguments: { shipment_id: shipment.id })
        else
          shipment.comment_without_state_change(comment: tracking.description, linked_object: tracking)
        end
      end
    end
  end
end
