class CarrierFeedbackConfiguration < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :latest_file, class_name: "CarrierFeedbackFile", required: false

  def carrier_name
  end

  def account_label
  end

  def carrier_type
  end
end
