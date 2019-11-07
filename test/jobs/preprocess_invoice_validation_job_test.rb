require "test_helper"

class PreprocessInvoiceValidationJobTest < ActiveJob::TestCase
  setup do
    @invoice_validation = FactoryBot.create(:invoice_validation)
  end

  test "it should perform and update status to empty_file when file is empty" do
    InvoiceValidation.test_file_name = "test/fixtures/invoice_validation_test_empty_file.xlsx"

    PreprocessInvoiceValidationJob.perform_now(@invoice_validation.id)

    @invoice_validation.reload

    assert @invoice_validation.empty_file?, "Status is: '#{@invoice_validation.status}', it is supposed to be 'empty_file'"
  end

  test "it should perform and update status to error_header when file header is not in the first line" do
    InvoiceValidation.test_file_name = "test/fixtures/invoice_validation_test_header_in_second_line.xlsx"

    PreprocessInvoiceValidationJob.perform_now(@invoice_validation.id)

    @invoice_validation.reload

    assert @invoice_validation.error_header?, "Status is: '#{@invoice_validation.status}', it is supposed to be 'header_error'"
  end

  test "it should perform and parse header when it is in file's first line" do
    InvoiceValidation.test_file_name = "test/fixtures/invoice_validation_test_header_in_first_line.xlsx"

    PreprocessInvoiceValidationJob.perform_now(@invoice_validation.id)

    @invoice_validation.reload

    assert @invoice_validation.preprocessed_file?, "Status is : '#{@invoice_validation.status}', it is supposed to be 'processed_file'"
    assert_equal @invoice_validation.header_row, { "A1"=>"company id", "B1"=>"shipment id", "C1"=>"manager id", "D1"=>"price", "E1"=>nil, "F1"=>nil, "G1"=>nil }
  end
end
