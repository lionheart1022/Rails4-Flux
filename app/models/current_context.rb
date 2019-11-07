module CurrentContext
  class << self
    def setup(params = {})
      UserContext.new(params)
    end

    def token_setup(params = {})
      TokenContext.new(params)
    end
  end

  class BaseContext
    def initialize(_)
    end

    def initiator
      raise "define in subclass"
    end

    def identifier
      raise "define in subclass"
    end

    def company
      raise "define in subclass"
    end

    def customer
      raise "define in subclass"
    end
  end

  class UserContext < BaseContext
    attr_reader :company
    attr_reader :customer

    def initialize(params = {})
      params.each do |attr, value|
        self.send("#{attr}=", value)
      end
    end

    def initiator
      user
    end

    def is_customer?
      is_customer
    end

    def is_admin?
      is_admin
    end

    def company_id
      company.id
    end

    def customer_id
      customer.id
    end

    def identifier
      user.email
    end

    ###########################################################################
    # Feature flag related methods
    def feature_flag_enabled?(identifier)
      FeatureFlag.active.where(resource: user, identifier: identifier).exists?
    end

    def company_feature_flag_enabled?(identifier)
      FeatureFlag.active.where(resource: company, identifier: identifier).exists?
    end

    def addon_enabled?(identfier)
      if is_customer?
        false
      else
        company.addon_enabled?(identfier)
      end
    end

    ###########################################################################
    # Shipment related methods

    def find_shipment(id)
      if is_customer?
        Shipment.find_customer_shipment(company_id: company_id, customer_id: customer_id, shipment_id: id)
      else
        Shipment.find_company_shipment(company_id: company_id, shipment_id: id)
      end
    end

    def new_shipment_based_on_existing(id:)
      shipment = nil

      if is_customer?
        shipment = Shipment.find_customer_shipment(company_id: company_id, customer_id: customer_id, shipment_id: id)
      else
        shipment = Shipment.find_company_shipment(company_id: company_id, shipment_id: id)
        shipment.build_customer if shipment.customer_responsible != company
      end

      shipment.adjust_past_shipping_date

      shipment
    end

    def shipment_note?(shipment)
      if is_customer?
        Note.where(creator: customer, linked_object: shipment).exists?
      else
        Note.where(creator: company, linked_object: shipment).exists?
      end
    end

    def find_shipment_note(shipment)
      if is_customer?
        Note.find_by(creator: customer, linked_object: shipment)
      else
        Note.find_by(creator: company, linked_object: shipment)
      end
    end

    def upsert_shipment_note!(shipment, *note_args)
      if is_customer?
        shipment.upsert_note!(customer, *note_args)
      else
        shipment.upsert_note!(company, *note_args)
      end
    end

    ###########################################################################
    # Carrier related methods

    def enabled_carriers(limit: nil)
      if is_customer?
        Carrier.find_enabled_customer_carriers(company_id: company_id, customer_id: customer_id).limit(limit)
      else
        Carrier.none # TODO: This method is not used for company users yet
      end
    end

    def search_enabled_carriers(search_term, limit: nil)
      if is_customer?
        Carrier.search_enabled_customer_carriers(company_id: company_id, customer_id: customer_id, carrier_name: search_term).limit(limit)
      else
        Carrier.none # TODO: This method is not used for company users yet
      end
    end

    ###########################################################################
    # Ferry booking related methods

    def find_ferry_booking_shipment(shipment_id)
      if is_customer?
        ferry_booking_shipments
          .find_customer_shipment(company_id: company_id, customer_id: customer_id, shipment_id: shipment_id)
      else
        ferry_booking_shipments
          .find_company_shipment(company_id: company_id, shipment_id: shipment_id)
      end
    end

    def ferry_booking_view(shipment)
      view = nil

      if is_customer?
        view = FerryBookingView.new(shipment)
        view.buyer = customer
      else
        view = FerryBookingView.new(shipment)
        view.seller = company
        view.show_customer_name(shipment.customer.name)
      end

      view
    end

    def new_ferry_booking_form(attrs = {})
      form = FerryBookingForm.new(attrs)

      if is_customer?
        form.for_customer(customer)
      else
        form.for_company(company)
      end

      form
    end

    def create_ferry_booking(form)
      interactor = ::CreateFerryBooking.new(form: form, context: self)
      interactor.perform!
      interactor
    end

    def edit_ferry_booking_form(shipment, params: nil)
      form = FerryBookingForm.edit_shipment(shipment)

      if is_customer?
        form.for_customer(customer)
      else
        form.for_company(company)
      end

      if params
        form.travel_date = nil # FIXME: This is a temporary hack so the input date takes precedence
        form.assign_attributes(params)
      end

      # We don't allow changing customer
      form.customer_selectable = false

      form
    end

    def update_ferry_booking(shipment, form:)
      interactor = ::UpdateFerryBooking.new(shipment: shipment, form: form, context: self)
      interactor.perform!
      interactor
    end

    def cancel_ferry_booking(shipment)
      FerryBooking.cancel_shipment(shipment, context: self)
    end

    def ferry_booking_no_carrier_product_on_ferry_product_error(args = {})
      "The selected ferry route has no related carrier product"
    end

    def ferry_booking_no_carrier_product_error(args = {})
      if is_customer?
        "You cannot perform ferry bookings due to lacking the #{args[:carrier_product_name]} carrier product"
      else
        "This customer cannot perform ferry bookings due to lacking the #{args[:carrier_product_name]} carrier product"
      end
    end

    ###########################################################################
    # Asset related methods

    def create_other_asset(shipment, asset_attributes:)
      interactor = ::CreateOtherAsset.new(context: self, shipment: shipment)
      interactor.asset_attributes = asset_attributes
      interactor.perform!
    end

    def other_asset_creator
      if is_customer?
        customer
      else
        company
      end
    end

    def allow_creating_other_asset?(shipment)
      if is_customer?
        true
      else
        shipment.product_responsible == company
      end
    end

    def destroy_asset(shipment_id:, asset_id:)
      interactor =
        if is_customer?
          ::Customers::Shipments::DestroyAsset.new(
            company_id: company_id,
            customer_id: customer_id,
            shipment_id: shipment_id,
            asset_id: asset_id,
          )
        else
          ::Companies::Shipments::DestroyAsset.new(
            company_id: company_id,
            shipment_id: shipment_id,
            asset_id: asset_id,
          )
        end

      result = interactor.run

      if result.try(:error)
        ExceptionMonitoring.report_message(result.error.message)
        false
      elsif result.try(:asset)
        result.try(:asset)
      else
        ExceptionMonitoring.report_message("Unexpected return value from DestroyAsset-interactor", context: { shipment_id: shipment_id, asset_id: asset_id })
        false
      end
    end

    ###########################################################################
    # e-conomic related methods

    def set_economic_agreement_grant_token!(token, self_response: nil)
      if is_customer?
        raise "Not supported for customers"
      else
        access = nil

        EconomicAccess.transaction do
          # Deactivate current e-conomic access token
          EconomicAccess.active.where(owner: company).update_all(active: false)

          # Create new
          access = EconomicAccess.create!(owner: company, agreement_grant_token: token, self_response: self_response)
        end

        access
      end
    end

    ###########################################################################
    # Contact related methods

    def contacts
      if is_customer?
        customer.contacts
      else
        company.contacts
      end
    end

    def add_contact_to_address_book!(*args, &block)
      if is_customer?
        contact = nil

        ActiveRecord::Base.transaction do
          customer.create_address_book! unless customer.address_book
          contact = customer.address_book.contacts.create!(*args, &block)
        end

        contact
      else
        company.add_contact_to_address_book!(*args, &block)
      end
    end

    def find_contact(contact_id)
      if is_customer?
        customer.contacts.find(contact_id)
      else
        company.contacts.find(contact_id)
      end
    end

    def autocomplete_contacts(term)
      if is_customer?
        customer.autocomplete_contacts(term)
      else
        company.autocomplete_contacts(term)
      end
    end

    private

    def ferry_booking_shipments
      Shipment
        .where(ferry_booking_shipment: true)
        .find_shipments_not_requested
    end

    attr_accessor :user
    attr_accessor :is_customer
    attr_accessor :is_admin
    attr_writer :company
    attr_writer :customer
  end

  class TokenContext < BaseContext
    attr_reader :company
    attr_reader :customer

    def initialize(params = {})
      params.each do |attr, value|
        self.send("#{attr}=", value)
      end
    end

    def initiator
      token
    end

    def is_customer?
      is_customer
    end

    def company_id
      company.id
    end

    def customer_id
      customer.id
    end

    def identifier
      token.value
    end

    def token_value
      token.value
    end

    private

    attr_accessor :token
    attr_accessor :is_customer
    attr_writer :company
    attr_writer :customer
  end

  private_constant :BaseContext, :UserContext
end
