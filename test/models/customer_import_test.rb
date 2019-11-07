require "test_helper"

class CustomerImportTest < ActiveSupport::TestCase
  test "stage_completed? when parsing has failed" do
    customer_import = CustomerImport.new
    customer_import.parsing_enqueued_at = Time.zone.now
    customer_import.status = CustomerImport::States::FAILED

    assert customer_import.stage_completed? "parsing"
    refute customer_import.parsing?
  end

  test "stage_completed? when performing has failed" do
    customer_import = CustomerImport.new
    customer_import.perform_enqueued_at = Time.zone.now
    customer_import.status = CustomerImport::States::FAILED

    assert customer_import.stage_completed? "creating"
    refute customer_import.creating?
  end
end
