class GLSCarrierProductCredential < CarrierProductCredential
  credential_field :username
  credential_field :password
  credential_field :customer_id
  credential_field :contact_id

  def form_partial_path
    "companies/carrier_product_credentials/form_for_gls"
  end

  def whitelist_params(credential_params)
    credential_params.permit(
      :username,
      :password,
      :customer_id,
      :contact_id,
    )
  end
end
