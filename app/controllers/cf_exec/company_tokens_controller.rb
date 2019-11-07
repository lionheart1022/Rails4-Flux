module CFExec
  class CompanyTokensController < ExecController
    def index
      @tokens = Token.all.includes(:owner).where(owner_type: "Company").order(:id).page(params[:page])
    end

    def show
      @token = Token.where(owner_type: "Company").find(params[:id])
    end

    def allow_unsafe_access
      @token = Token.where(owner_type: "Company").find(params[:id])
      @token.update!(force_ssl: false)

      redirect_to action: "show"
    end

    def force_safe_access
      @token = Token.where(owner_type: "Company").find(params[:id])
      @token.update!(force_ssl: true)

      redirect_to action: "show"
    end

    private

    def active_nav
      case params[:action]
      when "index"
        [:tokens, :company_token_index]
      when "show"
        [:tokens, :company_token_show]
      end
    end
  end
end
