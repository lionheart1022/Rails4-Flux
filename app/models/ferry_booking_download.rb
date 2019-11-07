class FerryBookingDownload < ActiveRecord::Base
  class << self
    def handle!
      unhandled.each do |download|
        download.with_lock do
          download.handle!
        end
      end
    end

    def sftp_download_and_save!(company:, host:, user:, password:, pattern:)
      Net::SFTP.start(host, user, password: password) do |sftp|
        sftp.dir.glob("./", pattern) do |entry|
          unique_identifier = "sftp_host:#{host} | sftp_user:#{user} | file_name:#{entry.name}"

          # Skip already downloaded files
          next if where(company: company, unique_identifier: unique_identifier).exists?

          document = sftp.download!(entry.name)

          create!(
            company: company,
            unique_identifier: unique_identifier,
            document: document,
            file_path: entry.name,
          )
        end
      end
    end
  end

  scope :unhandled, -> { where(parsed_at: nil) }

  belongs_to :company, required: true

  validates :unique_identifier, presence: true
  validates :file_path, presence: true
  validates :document, presence: true

  def parsed?
    parsed_at.present?
  end

  def handle!
    return if parsed?

    xml = Nokogiri::XML(document)
    msgtype = xml.at_css("datatransfer start msgtype").try(:text).to_s

    if msgtype != "CONFIRM"
      Rails.logger.tagged("FerryBookingDownload", "Handle.MsgType") do
        Rails.logger.error "Expected msgtype was not found (#{msgtype.try(:text).inspect})"
      end

      update!(parsed_at: Time.now)
      return
    end

    ActiveRecord::Base.transaction do
      xml.css("datatransfer > details").each do |details_node|
        ref = details_node.at_css("ref").try(:text).to_s

        if ref.blank?
          Rails.logger.tagged("FerryBookingDownload", id, "ref") do
            Rails.logger.error "Blank ref"
          end

          next
        end

        ferry_booking_request = FerryBookingRequest.where(ref: ref).last_handled_request

        if ferry_booking_request.nil?
          Rails.logger.tagged("FerryBookingDownload", id, "ref") do
            Rails.logger.error "Could not find ferry booking request matching ref (ref: #{ref.inspect})"
          end

          next
        end

        ferry_booking = ferry_booking_request.ferry_booking

        ferry_booking_response = ferry_booking.responses.new(download: self, result: { xml_fragment: details_node.to_xml })

        waybill = details_node.at_css("waybill").try(:text)
        addinfo1 = details_node.at_css("addinfo1").try(:text)
        addinfo2 = details_node.at_css("addinfo2").try(:text)
        traveltime = details_node.at_css("traveltime").try(:text)

        # The presence of a waybill is assumed to be a success-indicator
        if waybill.present?
          ferry_booking.check_and_register_updated_time_of_departure!(traveltime_hhmmss: traveltime)

          ferry_booking_response.event = ferry_booking_request.create_confirm_success_event!(description: "Successful response has been received from Scandlines:\n#{addinfo1}".strip)
          ferry_booking_request.register_confirm_success!(waybill: waybill, additional_info: addinfo2)
        else
          ferry_booking_response.event = ferry_booking_request.create_confirm_failure_event!(description: "Unsuccessful response has been received from Scandlines:\n#{addinfo1}".strip)
          ferry_booking_request.register_confirm_failure!
        end

        ferry_booking.update!(transfer_in_progress: false, waiting_for_response: false)

        ferry_booking_response.save!
      end

      update!(parsed_at: Time.now)
    end
  end
end
