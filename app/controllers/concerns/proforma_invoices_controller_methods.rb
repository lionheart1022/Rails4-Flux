module ProformaInvoicesControllerMethods
  extend ActiveSupport::Concern

  def show
    @shipment = current_context.find_shipment(params[:shipment_id])

    if @shipment
      render "admin/proforma_invoices/show", layout: "proforma_invoice"
    else
      render text: "Shipment not found", status: :not_found
    end
  end
end
