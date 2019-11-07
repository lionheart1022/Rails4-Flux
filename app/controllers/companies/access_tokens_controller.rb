class Companies::AccessTokensController < CompaniesController
  def index
    @view_model = Companies::TokenListView.new(current_company: current_company)
    @view_model.pagination = true
    @view_model.page = params[:page]
  end

  def create
    interactor = Companies::CreateToken.new(current_context: current_context, params: token_params)
    interactor.perform!

    redirect_to companies_access_token_path(interactor.token)
  end

  def show
    token = AccessToken.find(params[:id])

    case token.owner_type
    when "Company"
      raise "Cannot show company access token to this user" if token.owner != current_company
    when "Customer"
      raise "Cannot show customer access token to this user" if token.owner.company != current_company
    end

    @view_model = Companies::TokenDetailView.new(token)

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def token_params
    params.fetch(:token, {}).permit(
      :owner_id,
      :owner_type,
    )
  end

  def set_current_nav
    @current_nav = "tokens"
  end
end
