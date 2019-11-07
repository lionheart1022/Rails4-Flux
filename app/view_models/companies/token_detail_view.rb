class Companies::TokenDetailView < SimpleDelegator
  def title
    case token.owner_type
    when "Customer"
      "Customer / #{owner.name}"
    when "Company"
      owner.name
    end
  end

  def token_value
    token.value
  end

  def token_id
    token.id
  end

  def token
    __getobj__
  end
end
