require 'test_helper'

class FedExShipperLib::TrackingResponseTest < Minitest::Test
  describe 'TrackingResponse' do
    it 'parses a successful response' do
      success_response = File.read('test/fixtures/models/fed_ex/tracking_response.xml')
      response = FedExTrackingLib::TrackingResponse.new(success_response, '12341234')
      first_tracking = response.trackings[0]
      assert first_tracking.type == "FedExTracking"
      assert first_tracking.status == TrackingLib::States::DELIVERED
      assert first_tracking.description == "Delivered"
      assert first_tracking.event_time == Time.utc(2014, 7, 16, 16, 35, 0)
      assert first_tracking.event_date == Date.new(2014, 7, 16)
      assert first_tracking.event_city == "Prov"
      assert first_tracking.event_country == "United States"
      assert first_tracking.event_zip_code == "02903"
    end

    it 'parses a response with delivered event' do
      success_response = File.read('test/fixtures/models/fed_ex/tracking_response.xml')
      response = FedExTrackingLib::TrackingResponse.new(success_response, '12341234')
      second_tracking = response.trackings[1]
      assert second_tracking.status == TrackingLib::States::IN_TRANSIT
    end

    it 'parses a response with problematic event' do
      success_response = File.read('test/fixtures/models/fed_ex/tracking_response.xml')
      response = FedExTrackingLib::TrackingResponse.new(success_response, '12341234')
      third_tracking = response.trackings[2]
      assert third_tracking.status == TrackingLib::States::EXCEPTION
    end

    it 'parses a response with unkown event' do
      success_response = File.read('test/fixtures/models/fed_ex/tracking_response.xml')
      response = FedExTrackingLib::TrackingResponse.new(success_response, '12341234')
      third_tracking = response.trackings[3]
      assert third_tracking.status == nil
    end
  end
end
