namespace :ferry_bookings do
  desc "Create ferry routes for company"
  task :seed_routes_for_company, [:company_id] => [:environment] do |t, args|
    company = Company.find(args[:company_id])
    FerryRouteSeeds.new(company).perform!
  end

  desc "Create Scandlines carrier product for company"
  task :setup_carrier_product_for_company, [:company_id] => [:environment] do |t, args|
    company = Company.find(args[:company_id])

    if ScandlinesCarrierProduct.where(company: company).empty?
      scandlines_carrier_product = ScandlinesCarrierProduct.new(company: company, name: "Scandlines", state: CarrierProduct::States::UNLOCKED_FOR_CONFIGURING)
      scandlines_carrier_product.carrier = ScandlinesCarrier.new(company: company, name: "Scandlines")
      scandlines_carrier_product.save!

      puts "Created Scandlines carrier product for the company"
    else
      puts "A Scandlines carrier product already exists for the company"
    end
  end

  desc "Download responses from Scandlines SFTP"
  task :sftp_download => :environment do
    FerryBooking.waiting_for_response.each do |ferry_booking|
      ferry_booking.sftp_download_response!
    end

    FerryBookingDownload.handle!
  end

  desc "Handle incomplete requests"
  task :handle_requests => :environment do
    FerryBookingRequest.unhandled_and_older_than(10.minutes.ago).each do |ferry_booking_request|
      FerryBookingRequestJob.perform_later(ferry_booking_request.ferry_booking_id)
    end
  end

  desc "Archive succesful ferry bookings"
  task :archive, [:age_days] => [:environment] do |t, args|
    age_days =
      if args[:age_days]
        begin
          Integer(args[:age_days])
        rescue ArgumentError
          abort "Invalid `age_days` argument (#{args[:age_days].inspect})"
        end
      else
        2 # Default
      end

    abort "Age must be at least 1 day (it is set to #{age_days})" if age_days < 1

    archive_threshold_date = Date.today - age_days.days
    dry_run = ENV["FERRY_BOOKING_ARCHIVE_DRY_RUN"] == "1"

    ferry_bookings_to_archive =
      FerryBooking
      .editable
      .includes(:shipment)
      .where(shipments: { state: Shipment::States::BOOKED })
      .where(Shipment.arel_table[:shipping_date].lteq(archive_threshold_date))

    ferry_bookings_to_archive.each do |ferry_booking|
      Rails.logger.tagged("FerryBooking.Archival") do
        if dry_run
          Rails.logger.info "Archiving (dry run) ferry_booking=#{ferry_booking.id} shipment=#{ferry_booking.shipment_id}"
        else
          Rails.logger.info "Archiving ferry_booking=#{ferry_booking.id} shipment=#{ferry_booking.shipment_id}"
          ferry_booking.shipment.delivered_at_destination(comment: "Auto-archived")
        end
      end
    end
  end
end
