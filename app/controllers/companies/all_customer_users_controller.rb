class Companies::AllCustomerUsersController < CompaniesController
  def index
    @users =
      User
      .select("users.*, customers.name AS accessible_customer_name, customers.id AS accessible_customer_id")
      .order("users.email ASC, customers.id ASC")
      .joins(:user_customer_accesses => :customer)
      .where(user_customer_accesses: { company_id: current_company.id, revoked_at: nil })
      .page(params[:page])
  end

  private

  def set_current_nav
    @current_nav = "users"
  end
end
