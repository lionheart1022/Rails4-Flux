class CarrierProductAutobookRequestsAddDataField < ActiveRecord::Migration
  def change
    add_column(:carrier_product_autobook_requests, :data, :text)

    # Migrate existing data

    TNTCarrierProductAutobookRequest.all.each do |request|
      request.data = {
        tnt_access_id: nil,
        tnt_data: nil,
        tnt_error: nil,
        tnt_api_errors: [],
      }
      request.save!
    end
  end
end
