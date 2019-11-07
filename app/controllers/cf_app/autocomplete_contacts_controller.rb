module CFApp
  class AutocompleteContactsController < BaseAppController
    def index
      @contacts =
        current_context
        .autocomplete_contacts(params[:term])
        .order(:id)
        .page(params[:page])
        .per(Integer(params[:per].presence || 5))

      request.variant = :select2 if params[:variant] == "select2"

      respond_to do |format|
        format.json.select2
        format.json.none
      end
    end
  end
end
