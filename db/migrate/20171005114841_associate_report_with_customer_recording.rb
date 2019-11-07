class AssociateReportWithCustomerRecording < ActiveRecord::Migration
  def change
    add_reference :reports, :customer_recording
  end
end
