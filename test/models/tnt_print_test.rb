require "test_helper"
require "net/http"

class TNTPrintTest < ActiveSupport::TestCase
  def access_id
    ENV.fetch("TNT_PRINT_TEST_ACCESS_ID")
  end

  def tnt_request(params)
    uri = URI("https://express.tnt.com/expressconnect/shipping/ship")
    Net::HTTP.post_form(uri, params)
  end

  # Commented out so we don't make too many HTTP requests to TNT (resulting in a slow test case).
  # test "#generate_html! with consignment note" do
  #   connote_response = tnt_request("xml_in" => "GET_CONNOTE:#{access_id}")
  #   tnt_print = TNTPrint.new(xml_string: connote_response.body)
  #   tnt_print.generate_html!
  #
  #   assert tnt_print.output_html.present?
  # end
  #
  # test "#generate_html! with label" do
  #   label_response = tnt_request("xml_in" => "GET_LABEL:#{access_id}")
  #   tnt_print = TNTPrint.new(xml_string: label_response.body)
  #   tnt_print.generate_html!
  #
  #   assert tnt_print.output_html.present?
  # end

  test "#generate_pdf! with consignment note" do
    connote_response = tnt_request("xml_in" => "GET_CONNOTE:#{access_id}")
    pdf_output_path = Rails.root.join("tmp", "tnt_print_CONNOTE_#{access_id}.pdf")
    tnt_print = TNTPrint.new(xml_string: connote_response.body)
    tnt_print.generate_pdf!(pdf_output_path)

    assert File.exists?(pdf_output_path)
    assert File.size(pdf_output_path) > 0

    Rails.logger.info "PDF written to #{pdf_output_path}"
  end

  test "#generate_pdf! with label" do
    label_response = tnt_request("xml_in" => "GET_LABEL:#{access_id}")
    pdf_output_path = Rails.root.join("tmp", "tnt_print_LABEL_#{access_id}.pdf")
    tnt_print = TNTPrint.new(xml_string: label_response.body)
    tnt_print.generate_pdf!(pdf_output_path)

    assert File.exists?(pdf_output_path)
    assert File.size(pdf_output_path) > 0

    Rails.logger.info "PDF written to #{pdf_output_path}"
  end
end if ENV["TNT_PRINT_TEST"] == "1"
