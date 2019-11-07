module CFExec
  class LoginPagesController < ExecController
    def index
      @login_pages = CentralizedLoginPage.all.order(id: :asc)

      respond_to do |format|
        format.html
      end
    end

    private

    def active_nav
      case params[:action]
      when "index"
        [:companies, :login_pages__index]
      end
    end
  end
end
