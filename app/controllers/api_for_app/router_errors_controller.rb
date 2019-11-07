module APIForApp
  class RouterErrorsController < APIForAppController
    def not_found
      render "api_for_app/not_found", status: :not_found
    end
  end
end
