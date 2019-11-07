require "test_helper"

class ProcessInvoiceValidationJobTest < ActiveJob::TestCase
  setup do
    company_carrier_owner = FactoryBot.create(:company, :as_carrier_product_owner)
    shipment = FactoryBot.create(:shipment, :with_advanced_price, unique_shipment_id: "1-1-1", company: company_carrier_owner, carrier_product: company_carrier_owner.carrier_products.first)
    @invoice_validation = FactoryBot.create(:invoice_validation, company: company_carrier_owner)
  end

  test "it should parse and catch invoice errors" do
    InvoiceValidation.test_file_name = "test/fixtures/invoice_validation_test.xlsx"
    ProcessInvoiceValidationJob.perform_now(@invoice_validation.id)

    @invoice_validation.reload

    assert @invoice_validation.processed_file?, "Status is: '#{@invoice_validation.status}', it is supposed to be 'processed_file'"
    assert_equal @invoice_validation.invoice_validation_error_rows.count, 1
    assert_equal @invoice_validation.processed_shipments_count, 1
    assert_equal @invoice_validation.invoice_validation_error_rows.first.difference_price_amount.to_f, -7.1
  end

  test "it should update status to 'failed' when a problem occurs" do
    InvoiceValidation.test_file_name = "test/fixtures/nonexistant_file"
    ProcessInvoiceValidationJob.perform_now(@invoice_validation.id)

    @invoice_validation.reload

    assert @invoice_validation.failed?, "Status is: '#{@invoice_validation.status}', it is supposed to be 'failed'"
  end
end
