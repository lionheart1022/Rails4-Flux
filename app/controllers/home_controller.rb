class HomeController < ApplicationController
  helper_method :layout_config

  # GET /
  def index
    if @login_page = CentralizedLoginPage.find_by_domain(request.host)
      render :centralized_login_page, layout: "application"
      return
    end

    company = Company.find_company_with_domain(domain: request.host)
    return if company.nil?

    if user_signed_in?
      redirect_to admin_root_path
    else
      redirect_to new_user_session_path
    end
  end

  # POST login-page/:id/redirect
  def login_page_redirect
    login_page = CentralizedLoginPage.find(params[:id])

    email = params[:user].try(:[], :email).presence || params[:email]
    user = User.find_by_email(email)

    target_company = nil

    if user
      company_ids = UserCustomerAccess.active.where(user: user).pluck(:company_id) + [user.company_id]
      company_ids.compact!
      company_ids.uniq!

      target_companies = login_page.companies.where(id: company_ids)
      if target_companies.size > 1
        redirect_to login_page_select_path(user: { email: email })
        return
      else
        target_company = target_companies.first
      end
    end

    target_company ||= login_page.primary_company

    redirect_to new_user_session_url(host: target_company.domain, user: { email: email })
  end

  # GET login-page/:id/select
  def login_page_select
    @login_page = CentralizedLoginPage.find(params[:id])

    render layout: "application"
  end

  private

  def layout_config
    return nil if @login_page.nil?

    @_layout_config ||= begin
      config = LayoutConfig.new_from_company(@login_page.primary_company)

      config.body_class = "without_sidebar"
      config.root_path = root_path
      config.title = @login_page.title

      config
    end
  end
end
