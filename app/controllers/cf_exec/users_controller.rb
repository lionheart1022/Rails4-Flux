module CFExec
  class UsersController < ExecController
    def index
      @user_search = UserSearch.new(params.fetch(:search, {}).permit(:email))
      @users = @user_search.filtered_users.order(id: :asc).page(params[:page]).per(100)

      respond_to do |format|
        format.html
      end
    end

    def show
      @user = User.find(params[:id])
      @user_view = UserView.new(@user)
    end

    private

    def active_nav
      case params[:action]
      when "index"
        [:users, :index]
      when "show"
        [:users, :show]
      end
    end

    class UserSearch
      include ActiveModel::Model

      attr_accessor :email

      def filtered_users
        @filtered_users ||= filter_users!
      end

      private

      def filter_users!
        relation = User.all

        if pattern = email_pattern
          relation = relation.where("email ILIKE ?", pattern)
        end

        relation
      end

      def email_pattern
        if email.present?
          if match = email.match(%r{\A\|(.+)\|\z})
            match[1] # Treat queries inside a pair of pipes as escaped by the user.
          else
            "%#{escape_pattern(email)}%"
          end
        end
      end

      def escape_pattern(unescaped)
        unescaped
          .gsub("\\", "\\\\")
          .gsub("%", "\\%")
          .gsub("_", "\\_")
      end
    end

    class UserView < SimpleDelegator
      def notifications
        email_settings ? email_settings.slice(*EmailSettings::FLAG_ATTRIBUTES) : {}
      end

      def any_notifications?
        notifications.any? { |_, value| value }
      end
    end
  end
end
