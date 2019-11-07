class Customers::AccessTokensController < CustomersController
  def show
    @token = AccessToken.find_or_initialize_by(owner: current_customer)
  end

  def update
    AccessToken.transaction do
      token = AccessToken.where(owner: current_customer).find_or_initialize_by({})
      token.value = AccessToken.generate_token
      token.save!

      other_tokens_with_same_value = AccessToken.where.not(id: token.id).where(value: token.value)
      if other_tokens_with_same_value.exists?
        # TODO: This should be handled at the DB-level with an uniqueness constraint.
        raise "The generated access token is not unique"
      end
    end

    redirect_to customers_access_token_path, notice: "Updated access token"
  end

  private

  def set_current_nav
    @current_nav = "tokens"
  end
end
