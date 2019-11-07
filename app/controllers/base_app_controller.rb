class BaseAppController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_nav

  before_action :handle_blank_current_customer_identifier, if: -> { params[:app_scope] == "customers" }
  before_action :ensure_user_is_customer, if: -> { params[:app_scope] == "customers" }
  before_action :set_body_class_for_customer, if: -> { params[:app_scope] == "customers" }

  before_action :ensure_user_is_company_user, if: -> { params[:app_scope] == "companies" }
  before_action :set_body_class_for_company, if: -> { params[:app_scope] == "companies" }

  layout :determine_layout

  helper_method :current_context
  helper_method :current_customer
  helper_method :current_company
  helper_method :navigation
  helper_method :layout_config

  private

  def current_context
    case params[:app_scope]
    when "companies"
      @current_context ||= CurrentContext.setup(
        user: current_user,
        is_customer: current_user.is_customer,
        is_admin: current_user.is_admin,
        company: current_user.company,
        customer: current_user.customer,
      )
    when "customers"
      @current_context ||= CurrentContext.setup(
        user: current_user,
        is_customer: current_customer.present?,
        is_admin: false,
        company: current_company,
        customer: current_customer,
      )
    end
  end

  def current_customer_access
    case params[:app_scope]
    when "companies"
      nil
    when "customers"
      if defined?(@current_customer_access)
        @current_customer_access
      else
        @current_customer_access = current_user.find_customer_with_access_to_by_params_identifier(params[:current_customer_identifier])
      end
    end
  end

  def current_customer
    case params[:app_scope]
    when "companies"
      nil
    when "customers"
      if defined?(@current_customer)
        @current_customer
      else
        @current_customer = current_customer_access ? current_customer_access.customer : nil
      end
    end
  end

  def current_company
    case params[:app_scope]
    when "companies"
      if current_user
        @current_company ||= current_user.company
      else
        nil
      end
    when "customers"
      if defined?(@current_company)
        @current_company
      else
        @current_company = current_customer ? current_customer.company : nil
      end
    end
  end

  def default_url_options
    case params[:app_scope]
    when "companies"
      super
    when "customers"
      if current_customer_access.nil?
        # Without this the redirect to admin root will potentionally include the `current_customer_identifier`-param
        super
      else
        { current_customer_identifier: current_customer_access.params_identifier }
      end
    end
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

  def ensure_user_is_company_user
    if current_context.is_customer?
      flash[:notice] = "Only company users are allowed to do that."
      redirect_to :admin_root
    end
  end

  def navigation
    case params[:app_scope]
    when "companies"
      @_navigation_view_model ||= AdminNavigation.for_company(current_company)
    when "customers"
      @_navigation_view_model ||= AdminNavigation.for_customer(customer: current_customer, company: current_company)
    end
  end

  def layout_config
    case params[:app_scope]
    when "companies"
      @_layout_config ||= begin
        config = LayoutConfig.new_from_company(current_company)

        config.body_class = @body_class
        config.root_path = admin_root_path

        config
      end
    when "customers"
      @_layout_config ||= begin
        config = LayoutConfig.new_from_company(current_company)

        config.body_class = @body_class
        config.root_path = customers_shipments_path

        config
      end
    end
  end

  def set_current_nav
    # Override in subclasses
  end

  def set_body_class_for_customer
    set_body_class("customers")
  end

  def set_body_class_for_company
    set_body_class("companies")
  end

  def set_body_class(name)
    @body_class = name
  end

  def determine_layout
    case params[:app_scope]
    when "companies"
      "companies"
    when "customers"
      "customers"
    end
  end
end
