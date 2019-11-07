class CustomersController < AdminController
  before_action :handle_blank_current_customer_identifier
  before_action :set_body_class_for_customer
  before_action :ensure_user_is_customer
  helper_method :navigation
  helper_method :layout_config

  private

  def current_context
    @current_context ||= CurrentContext.setup(
      user: current_user,
      is_customer: current_customer.present?,
      is_admin: false,
      company: current_company,
      customer: current_customer,
    )
  end

  def current_customer_access
    if defined?(@current_customer_access)
      @current_customer_access
    else
      @current_customer_access = current_user.find_customer_with_access_to_by_params_identifier(params[:current_customer_identifier])
    end
  end

  def current_customer
    if defined?(@current_customer)
      @current_customer
    else
      @current_customer = current_customer_access ? current_customer_access.customer : nil
    end
  end

  def current_company
    if defined?(@current_company)
      @current_company
    else
      @current_company = current_customer ? current_customer.company : nil
    end
  end

  def default_url_options
    return super if current_customer_access.nil? # Without this the redirect to admin root will potentionally include the `current_customer_identifier`-param

    { current_customer_identifier: current_customer_access.params_identifier }
  end

  def handle_blank_current_customer_identifier
    return if params[:current_customer_identifier].present?

    resolver = UserAccessResolver.new(current_user, host: request.host)
    resolver.perform!

    if resolver.access_to_single_customer?
      redirect_to url_for(current_customer_identifier: resolver.current_customer_identifier)
    else
      redirect_to account_selector_path
    end
  end

  def ensure_user_is_customer
    unless current_context.is_customer?
      flash[:notice] = "You do not have access to that customer"
      redirect_to :admin_root
    end
  end

  def navigation
    @_navigation_view_model ||= AdminNavigation.for_customer(customer: current_customer, company: current_company)
  end

  def layout_config
    @_layout_config ||= begin
      config = LayoutConfig.new_from_company(current_company)

      config.body_class = @body_class
      config.root_path = customers_shipments_path

      config
    end
  end

  def set_body_class_for_customer
    set_body_class("customers")
  end
end
