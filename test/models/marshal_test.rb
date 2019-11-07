require "test_helper"

# This is how test/fixtures/price_document-price_single_multi_zone_dk.marshal was initially generated:
#
#   price_document = TestPriceDocuments.price_single_multi_zone_dk
#   marshalled_price_document_file_path = Rails.root.join("test", "fixtures", "price_document-price_single_multi_zone_dk.ruby-#{RUBY_VERSION}.marshal")
#   File.open(marshalled_price_document_file_path, "wb") { |file| file.write(Marshal.dump(price_document)) }

class MarshalTest < ActiveSupport::TestCase
  test "price document marshalled in Ruby 2.1.5 is not changed in current Ruby version" do
    price_document = TestPriceDocuments.price_single_multi_zone_dk
    marshalled_price_document_file_path = Rails.root.join("test", "fixtures", "price_document-price_single_multi_zone_dk.ruby-2.1.5.marshal")

    File.open(marshalled_price_document_file_path, "rb") do |file|
      assert_equal file.read, Marshal.dump(price_document), "Marshalled price document has changed - this is maybe not a big issue"
    end
  end
end
