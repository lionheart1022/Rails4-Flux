module UserAccessResolving
  extend ActiveSupport::Concern

  included do
    helper_method :user_access_symbol
  end

  private

  def user_access_resolver
    raise "User must be signed in" unless user_signed_in?

    @_user_access_resolver ||= begin
      resolver = UserAccessResolver.new(current_user, host: request.host)
      resolver.perform!
      resolver
    end
  end

  def user_access_symbol
    @_user_access_symbol ||= begin
      if user_access_resolver.access_to_single_customer?
        :single_customer
      elsif user_access_resolver.access_to_single_company?
        :single_company
      else
        :multiple
      end
    end
  end
end
