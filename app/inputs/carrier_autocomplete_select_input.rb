class CarrierAutocompleteSelectInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= "string"

    input_html_options[:data] ||= {}
    input_html_options[:data][:behavior] = "remote_input_to_select2"
    input_html_options[:data][:"ajax--url"] = template.url_for(controller: "autocomplete_carriers", action: "index", variant: "select2", format: "json")
    input_html_options[:data][:theme] = "cargoflux"

    if (selected_option_text = carrier_name)
      input_html_options[:data][:"selected-option-text"] = selected_option_text
    end

    super
  end

  private

  def carrier_name
    carrier_id.present? ? Carrier.where(id: carrier_id).first.try(:name) : nil
  end

  def carrier_id
    object.send(attribute_name)
  end
end
