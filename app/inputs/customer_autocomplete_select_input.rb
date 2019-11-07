class CustomerAutocompleteSelectInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= "string"

    input_html_options[:data] ||= {}
    input_html_options[:data][:behavior] = "remote_input_to_select2"
    input_html_options[:data][:"ajax--url"] = template.companies_autocomplete_direct_customers_path(format: "json", variant: "select2")
    input_html_options[:data][:theme] = "cargoflux"

    if _customer_name = customer_name
      input_html_options[:data][:"selected-option-text"] = _customer_name
    end

    super
  end

  private

  def customer_name
    customer_id.present? ? Customer.where(id: customer_id).pluck(:name).first : nil
  end

  def customer_id
    object.send(attribute_name)
  end
end
