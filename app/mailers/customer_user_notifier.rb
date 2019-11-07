class CustomerUserNotifier < ApplicationMailer
  # Sends a mail to new users with a link to confirm and select a password.
  def welcome_new_user(user:, customer:, raw_confirmation_token:)
    @user = user
    @customer = customer
    @company = customer.company
    @raw_confirmation_token = raw_confirmation_token

    mail(from: @company.action_mailer_from_email, to: user.email, subject: "Welcome to CargoFlux")
  end

  # Sends a mail to existing users.
  def welcome_already_confirmed_user(user:, customer:)
    @user = user
    @customer = customer
    @company = customer.company

    mail(from: @company.action_mailer_from_email, to: user.email, subject: "Access to new CargoFlux account")
  end
end
