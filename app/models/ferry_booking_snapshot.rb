class FerryBookingSnapshot < ActiveRecord::Base
  belongs_to :event, class_name: "FerryBookingEvent", required: true
end
