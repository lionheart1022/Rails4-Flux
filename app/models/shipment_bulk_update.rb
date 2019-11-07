class ShipmentBulkUpdate
  class << self
    def perform!(*args)
      new(*args).perform!
    end
  end

  class BaseError < StandardError
  end

  class MissingRequiredParam < BaseError
  end

  class ExceededMaximumUpdates < BaseError
  end

  attr_reader :current_company
  attr_reader :request_id
  attr_reader :operations

  def initialize(current_company:, payload:, max_number_of_updates: nil, request_id: nil)
    @current_company = current_company
    @request_id = request_id
    @operations = parse_operations_from_payload(payload)

    if max_number_of_updates && @operations.count > max_number_of_updates
      raise ExceededMaximumUpdates, "max number of updates (#{max_number_of_updates}) was exceeded (actual # of updates: #{@operations.count})"
    end
  end

  def perform!
    ActiveRecord::Base.transaction do
      perform_updates!
    end

    perform_uploads!

    build_result
  end

  private

  def perform_updates!
    shipments_grouped_by_id = build_shipment_map

    operations.each do |operation|
      shipment = shipments_grouped_by_id[operation.unique_shipment_id]
      next if shipment.nil?
      next unless can_update_shipment_state?(shipment)

      if operation.update_state?
        interactor = Companies::ProcessShipmentStateChange.new(company: current_company, shipment: shipment, state_change_params: operation.state_change_params)
        interactor.perform!
      end
    end
  end

  def perform_uploads!
    shipments_grouped_by_id = build_shipment_map

    operations.each do |operation|
      shipment = shipments_grouped_by_id[operation.unique_shipment_id]
      next if shipment.nil?

      if operation.upload_assets?
        UploadShipmentAssetsJob.perform_later(shipment.id, operation.asset_urls_to_upload, request_id: request_id)
      end
    end
  end

  def build_shipment_map
    grouped_shipments = shipments_to_update.to_a.group_by(&:unique_shipment_id)

    grouped_shipments.each_key do |key|
      grouped_shipments[key] = grouped_shipments[key].first
    end

    grouped_shipments
  end

  def build_result
    shipments_grouped_by_id = build_shipment_map

    result = Result.new

    result.shipments = operations.map do |operation|
      shipment = shipments_grouped_by_id[operation.unique_shipment_id]

      if shipment && include_shipment_state_in_result?(shipment)
        {
          shipment_id: shipment.unique_shipment_id,
          awb: shipment.awb,
          state: shipment.state,
        }
      else
        {
          shipment_id: nil,
          awb: nil,
          state: nil,
        }
      end
    end

    result.shipment_assets = operations.map do |operation|
      shipment = shipments_grouped_by_id[operation.unique_shipment_id]

      if shipment
        {
          shipment_id: nil,
          asset_urls_to_upload: operation.asset_urls_to_upload,
        }
      else
        {
          shipment_id: nil,
          asset_urls_to_upload: nil,
        }
      end
    end

    result
  end

  def shipments_to_update
    unique_shipment_ids = operations.map(&:unique_shipment_id)
    Shipment.find_company_shipments(company_id: current_company.id).where(unique_shipment_id: unique_shipment_ids)
  end

  def parse_operations_from_payload(payload)
    raise ArgumentError, 'payload is `nil`' if payload.nil?
    raise MissingRequiredParam, "payload is expected to have 'updates' key" unless payload.key?('updates')

    payload['updates'].map do |update_as_hash|
      Operation.new(update_as_hash)
    end
  end

  def can_update_shipment_state?(shipment)
    shipment.product_responsible == current_company
  end

  def include_shipment_state_in_result?(shipment)
    shipment.company == current_company || Shipment.find_company_shipment(company_id: current_company.id, shipment_id: shipment.id)
  end

  Result = Struct.new(:shipments, :shipment_assets)

  class Operation
    attr_accessor :shipment_id
    attr_accessor :state_change
    attr_accessor :upload_label_from_url
    attr_accessor :upload_invoice_from_url
    attr_accessor :upload_consignment_note_from_url

    alias unique_shipment_id shipment_id

    def initialize(params = {})
      params.each do |attr, value|
        public_send("#{attr}=", value)
      end
    end

    def update_state?
      state_change.present? && state_change['new_state'].present?
    end

    def state_change_params
      return {} unless state_change

      {
        state: state_change['new_state'],
        awb: state_change['awb'],
        comment: state_change['comment'],
      }
    end

    def upload_assets?
      asset_urls_to_upload.keys.count > 0
    end

    def asset_urls_to_upload
      {
        'awb' => upload_label_from_url,
        'invoice' => upload_invoice_from_url,
        'consignment_note' => upload_consignment_note_from_url,
      }.reject { |_, url| url.blank? }
    end
  end
end
