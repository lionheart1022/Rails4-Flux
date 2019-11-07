class PasswordResetJob < ActiveJob::Base
  queue_as :imports

  def perform(email)
    user = User.find_by_email(email)

    if user
      user.send_reset_password_instructions
    else
      Rails.logger.info "Password reset was requested for unknown email=#{email}"
    end
  end
end
