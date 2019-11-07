class Package < ActiveRecord::Base
  belongs_to :shipment, required: true
  belongs_to :active_recording, class_name: "PackageRecording"

  has_many :recordings, class_name: "PackageRecording"

  def applicable_surcharge_types
  end
end
