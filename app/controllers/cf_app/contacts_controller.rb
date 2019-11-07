module CFApp
  class ContactsController < BaseAppController
    before_action :set_contact, except: [:index, :new, :create]

    def index
      @contacts = current_context.contacts
    end

    def new
      @contact = Contact.new
    end

    def create
      @contact = current_context.add_contact_to_address_book!(contact_params) do |contact|
        contact.set_country_name_from_code = true
      end

      redirect_to action: "show", id: @contact.id
    end

    def show
    end

    def edit
    end

    def update
      @contact.assign_attributes(contact_params)
      @contact.set_country_name_from_code = true
      @contact.save!

      redirect_to action: "show"
    end

    def destroy
      @contact.destroy!

      redirect_to action: "index"
    end

    private

    def contact_params
      params.require(:contact).permit(
        :company_name,
        :attention,
        :address_line1,
        :address_line2,
        :address_line3,
        :zip_code,
        :city,
        :country_code,
        :state_code,
        :phone_number,
        :email,
        :cvr_number,
        :note,
        :residential,
      )
    end

    def set_contact
      @contact = current_context.find_contact(params[:id])
    end

    def set_current_nav
      @current_nav = "contacts"
    end
  end
end
