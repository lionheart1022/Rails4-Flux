module APIForApp
  class SessionsController < APIForAppController
    skip_before_action :authenticate!, only: :create

    def create
      session_params = new_session_params

      if user = user_for_new_session
        truck_driver = user.truck_driver

        @token_session = TruckDriverSession.create_and_generate_unique_token!(
          company: truck_driver.company,
          sessionable: user.truck_driver,
          metadata: {
            "platform" => session_params[:platform],
            "user_agent" => request.headers["User-Agent"],
          }
        )

        render :success_session, status: :created
      else
        render :failure_session
      end
    rescue ActionController::ParameterMissing
      render :blank_body, status: :bad_request
    end

    def show
    end

    def destroy
      current_token_session.expire!(reason: "logout")

      head :accepted
    end

    private

    def user_for_new_session
      session_params = new_session_params
      user = User.all.joins(:truck_driver).find_by_email(session_params[:email])

      if Rails.env.development? || Rails.env.staging?
        if request.headers["X-CF-Fake-Session"] == "1"
          return user
        end
      end

      if user && user.valid_password?(session_params[:password])
        user
      end
    end

    def new_session_params
      params.require(:session).permit(:email, :password, :platform)
    end
  end
end
