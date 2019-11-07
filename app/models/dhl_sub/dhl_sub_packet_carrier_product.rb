class DHLSubPacketCarrierProduct < DHLSubGenericCarrierProduct

  def ignore_dutiable?
    true
  end

  def service
    'EPN'
  end

end
