module CarrierFeedbackSurcharge
  extend ActiveSupport::Concern

  def carrier_feedback_surcharge?
    true
  end

  def default_surcharge?
    false
  end

  def calculated_method_locked_to
    "price_fixed"
  end
end
