module CustomLabelsControllerMethods
  extend ActiveSupport::Concern

  def show
    shipment = current_context.find_shipment(params[:shipment_id])

    if shipment.nil?
      render text: "Shipment not found", status: :not_found
      return
    end

    unless shipment.carrier_product.custom_label?
      render text: "This shipment has no custom label", status: :not_found
      return
    end

    label_variant = Rails.env.development? ? params[:label_variant].presence : nil
    label_variant ||= shipment.carrier_product.custom_label_variant

    case label_variant
    when "samskip"
      @view_model = CustomLabelVariants::SamskipViewModel.new(shipment)
      render "admin/custom_labels/show", layout: "samskip_label"
    when "new_default_107x165"
      @view_model = CustomLabelVariants::NewDefaultViewModel.new(shipment: shipment, current_context: current_context)
      @page_width, @page_height = "107mm", "165mm"
      render "admin/custom_labels/show", layout: "new_default_label"
    when "new_default_107x190"
      @view_model = CustomLabelVariants::NewDefaultViewModel.new(shipment: shipment, current_context: current_context)
      @page_width, @page_height = "107mm", "190mm"
      render "admin/custom_labels/show", layout: "new_default_label"
    else
      @view_model = Shared::CustomLabel.new(current_company: current_company, shipment: shipment, sender: shipment.sender, recipient: shipment.recipient)
      render "admin/custom_labels/show", layout: "label"
    end
  end
end
