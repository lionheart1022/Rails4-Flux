module CarrierProductHelper

  def suffixed_name(name: nil, company: nil)
    initials = company.try(:initials) && company.initials.upcase
    name = "#{name} (#{initials})" if initials.present?

    name
  end

end
