require "open-uri"

class UploadShipmentAssetsJob < ActiveJob::Base
  queue_as :booking

  def perform(shipment_id, asset_urls, request_id: nil)
    Rails.logger.tagged(request_id) do
      Rails.logger.info "Uploading assets for shipment ID=#{shipment_id}"

      shipment = Shipment.find(shipment_id)

      fetch_awb_asset(shipment, asset_urls["awb"]) if asset_urls["awb"].present?
      fetch_consignment_note_asset(shipment, asset_urls["consignment_note"]) if asset_urls["consignment_note"].present?
      fetch_invoice_asset(shipment, asset_urls["invoice"]) if asset_urls["invoice"].present?
    end
  end

  private

  def fetch_awb_asset(shipment, url)
    Rails.logger.info "Uploading asset: AWB label"

    file = open(url)

    ActiveRecord::Base.transaction do
      shipment.build_asset_awb unless shipment.asset_awb

      shipment.asset_awb.attachment = file
      shipment.asset_awb.save!

      # TODO: We should not really be calling a private method - this is just a temporary workaround.
      shipment.send(:create_event, event_type: Shipment::Events::ASSET_AWB_UPLOADED, description: shipment.asset_awb.attachment_file_name)
    end
  rescue => e
    ExceptionMonitoring.report(e, context: { shipment_id: shipment.id, url: url })
  end

  def fetch_consignment_note_asset(shipment, url)
    Rails.logger.info "Uploading asset: consignment note"

    file = open(url)

    ActiveRecord::Base.transaction do
      shipment.build_asset_consignment_note unless shipment.asset_consignment_note

      shipment.asset_consignment_note.attachment = file
      shipment.asset_consignment_note.save!

      # TODO: We should not really be calling a private method - this is just a temporary workaround.
      shipment.send(:create_event, event_type: Shipment::Events::ASSET_CONSIGNMENT_NOTE_UPLOADED, description: shipment.asset_consignment_note.attachment_file_name)
    end
  rescue => e
    ExceptionMonitoring.report(e, context: { shipment_id: shipment.id, url: url })
  end

  def fetch_invoice_asset(shipment, url)
    Rails.logger.info "Uploading asset: invoice"

    file = open(url)

    ActiveRecord::Base.transaction do
      shipment.build_asset_invoice unless shipment.asset_invoice

      shipment.asset_invoice.attachment = file
      shipment.asset_invoice.save!

      # TODO: We should not really be calling a private method - this is just a temporary workaround.
      shipment.send(:create_event, event_type: Shipment::Events::ASSET_INVOICE_UPLOADED, description: shipment.asset_invoice.attachment_file_name)
    end
  rescue => e
    ExceptionMonitoring.report(e, context: { shipment_id: shipment.id, url: url })
  end
end
