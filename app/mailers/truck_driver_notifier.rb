class TruckDriverNotifier < ApplicationMailer
  # Sends a mail to new users with a link to confirm and select a password.
  def welcome_new_user(user:, company:, raw_confirmation_token:)
    @user = user
    @company = company
    @raw_confirmation_token = raw_confirmation_token

    mail(to: user.email, subject: "Welcome to CargoFlux")
  end
end
