class AdminController < ApplicationController
  respond_to :html

  before_action :authenticate_user!
  before_action :set_current_nav

  helper_method :current_context, :current_customer, :current_company

  rescue_from PermissionError, with: :respond_with_permission_error

  def current_context
    if defined?(@current_context)
      @current_context
    else
      @current_context = CurrentContext.setup(
        user: current_user,
        is_customer: current_user.is_customer,
        is_admin: current_user.is_admin,
        company: current_user.company,
        customer: current_user.customer,
      )
    end
  end

  def current_customer
    return nil unless current_user
    @current_customer ||= current_user.customer
  end

  def current_company
    return nil unless current_user
    @current_company ||= current_user.company
  end

  # Overwritten in child controllers
  def set_current_nav
  end

  protected

  def respond_with_permission_error(exception)
    flash[:error] = exception.message
    redirect_to admin_root_path
  end

  def respond_with_access_error
    flash[:error] = "You dont have access to this page"
    redirect_to admin_root_path
  end

  def set_body_class(name)
    @body_class = name
  end

end
