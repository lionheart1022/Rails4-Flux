module CFExec
  class GLSFeedbackConfigurationsController < ExecController
    def create
      company = Company.find(params[:company_id])
      configuration = company.gls_feedback_configurations.new(params.fetch(:config, {}).permit(:account_no))

      if configuration.account_details.present?
        if GLSFeedbackConfiguration.with_account_number(configuration.account_details['short_customer_no']).empty?
          configuration.set_credentials_from_env!
          configuration.save!
        end
      end

      redirect_to exec_company_path(company)
    end
  end
end
