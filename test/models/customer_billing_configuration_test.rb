require "test_helper"

class CustomerBillingConfigurationTest < ActiveSupport::TestCase
  test "schedules initial auto report request" do
    company_a = Company.create!(name: "Company A", current_customer_id: 0, current_report_id: 0)
    customer_a = company_a.create_customer!(name: "Customer A")
    customer_a_recording = company_a.find_customer_recording(customer_a)

    billing_configuration_params = {
      enabled: true,
      day_interval: 7,
      with_detailed_pricing: false,
    }
    CustomerBillingConfiguration.update_for_customer_recording(customer_a_recording, params: billing_configuration_params)

    travel 6.days do
      assert_equal 0, AutomatedReportRequest.scheduled_to_run.count
    end

    travel 8.days do
      assert_equal 1, AutomatedReportRequest.scheduled_to_run.count
    end
  end

  test "schedules next auto report request with correct timing" do
    company_a = Company.create!(name: "Company A", current_customer_id: 0, current_report_id: 0)
    customer_a = company_a.create_customer!(name: "Customer A")
    customer_a_recording = company_a.find_customer_recording(customer_a)

    billing_configuration_params = {
      enabled: true,
      day_interval: 7,
      with_detailed_pricing: false,
    }
    billing_configuration = CustomerBillingConfiguration.update_for_customer_recording(customer_a_recording, params: billing_configuration_params)

    handle_scheduled_requests_at = (Time.zone.now + 8.days).change(min: 40)

    travel_to handle_scheduled_requests_at do
      assert_equal 1, AutomatedReportRequest.scheduled_to_run.count

      AutomatedReportRequest.handle_requests_scheduled_to_run!
    end

    assert_equal 1, AutomatedReportRequest.handled.count
    assert_equal 1, AutomatedReportRequest.unhandled.count

    initial_report_request = AutomatedReportRequest.handled.first
    new_report_request = AutomatedReportRequest.unhandled.first

    assert_equal initial_report_request.run_at.change(min: 0, sec: 0), initial_report_request.run_at
    assert_equal initial_report_request.run_at + 7.days, new_report_request.run_at
  end

  test "schedules next auto report request with correct timing for very delayed handling" do
    company_a = Company.create!(name: "Company A", current_customer_id: 0, current_report_id: 0)
    customer_a = company_a.create_customer!(name: "Customer A")
    customer_a_recording = company_a.find_customer_recording(customer_a)

    billing_configuration_params = {
      enabled: true,
      day_interval: 7,
      with_detailed_pricing: false,
    }
    billing_configuration = CustomerBillingConfiguration.update_for_customer_recording(customer_a_recording, params: billing_configuration_params)

    handle_scheduled_requests_at = (Time.zone.now + 20.days)

    travel_to handle_scheduled_requests_at do
      assert_equal 1, AutomatedReportRequest.scheduled_to_run.count

      AutomatedReportRequest.handle_requests_scheduled_to_run!
    end

    assert_equal 1, AutomatedReportRequest.handled.count
    assert_equal 1, AutomatedReportRequest.unhandled.count

    initial_report_request = AutomatedReportRequest.handled.first
    new_report_request = AutomatedReportRequest.unhandled.first

    assert_equal initial_report_request.run_at.change(min: 0, sec: 0), initial_report_request.run_at
    assert_equal (handle_scheduled_requests_at + 7.days).change(min: 0, sec: 0), new_report_request.run_at
  end
end
