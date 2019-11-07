module FerryBookingsControllerMethods
  extend ActiveSupport::Concern

  included do
    before_action :set_shipment, only: [:show]
    before_action :set_editable_shipment, only: [:edit, :update, :cancel]
  end

  def new
    form = current_context.new_ferry_booking_form
    @view_model = view_model_for_new(form: form)

    render "admin/ferry_bookings/new"
  end

  def create
    form = current_context.new_ferry_booking_form(ferry_booking_new_params)
    interactor = current_context.create_ferry_booking(form)

    if interactor.success?
      redirect_to url_for(action: "index", controller: "shipments"), notice: "Created ferry booking!"
    else
      @view_model = view_model_for_new(form: form)

      render "admin/ferry_bookings/new"
    end
  end

  def show
    @view_model = current_context.ferry_booking_view(@shipment)

    render "admin/ferry_bookings/show"
  end

  def edit
    form = current_context.edit_ferry_booking_form(@shipment)
    @view_model = view_model_for_edit(form: form)

    render "admin/ferry_bookings/edit"
  end

  def update
    form = current_context.edit_ferry_booking_form(@shipment, params: ferry_booking_edit_params)
    interactor = current_context.update_ferry_booking(@shipment, form: form)

    if interactor.success?
      redirect_to url_for(action: "index", controller: "shipments"), notice: "Modified ferry booking!"
    else
      @view_model = view_model_for_edit(form: form)

      render "admin/ferry_bookings/edit"
    end
  end

  def cancel
    if current_context.cancel_ferry_booking(@shipment)
      redirect_to url_for(action: "index", controller: "shipments"), notice: "Cancelled ferry booking!"
    else
      redirect_to url_for(action: "show", controller: "shipments", id: params[:id]), notice: "Could not cancel ferry booking"
    end
  end

  private

  def view_model_for_new(form:)
    OpenStruct.new(
      form: form,
      form_url: url_for(action: "create"),
      form_method: :post,
      cancel_url: url_for(action: "index", controller: "shipments"),
      cancel_text: "Cancel",
      submit_text: "Create",
    )
  end

  def view_model_for_edit(form:)
    OpenStruct.new(
      form: form,
      shipment: @shipment,
      form_url: url_for(action: "update", controller: "shipments"),
      form_method: :patch,
      cancel_url: url_for(action: "index", controller: "shipments"),
      cancel_text: "Cancel editing",
      submit_text: "Update booking",
    )
  end

  def ferry_booking_new_params
    {} # Override in included class to whitelist params
  end

  def ferry_booking_edit_params
    {} # Override in included class to whitelist params
  end

  def set_current_nav
    @current_nav = "shipments"
  end

  def set_shipment
    @shipment = current_context.find_ferry_booking_shipment(params[:id])
    @current_nav = "shipments_archived" if [Shipment::States::CANCELLED].include?(@shipment.state)
  end

  def set_editable_shipment
    set_shipment

    begin
      @ferry_booking = FerryBooking.editable.find_by_shipment_id!(params[:id])
    rescue ActiveRecord::RecordNotFound
      if Rails.env.development?
        # In development let's just allow editing no matter what
        @ferry_booking = FerryBooking.find_by_shipment_id!(params[:id])
      else
        raise
      end
    end
  end
end
