class GLSPackage < Package
  def applicable_surcharge_types
    return [] if active_recording.nil? || active_recording.fee_data.nil?

    types = []
    types << "GLSSurcharges::NotSystemConformal" if active_recording.fee_data["NotSystemConformal"] == "True"
    types << "GLSSurcharges::OverSize" if active_recording.fee_data["OverSize"] == "True"
    types
  end
end
