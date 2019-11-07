class FerryBookingResponse < ActiveRecord::Base
  belongs_to :ferry_booking, required: true
  belongs_to :event, required: false, class_name: "FerryBookingEvent"
  belongs_to :download, required: false, class_name: "FerryBookingDownload"
end
