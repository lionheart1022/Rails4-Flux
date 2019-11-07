class CustomerRecordingSelectInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    input_html_options[:class] ||= "string"

    input_html_options[:data] ||= {}
    input_html_options[:data][:behavior] = "remote_input_to_select2"
    input_html_options[:data][:"ajax--url"] = template.companies_autocomplete_customer_recordings_path(format: "json", variant: "select2")
    input_html_options[:data][:theme] = "cargoflux"

    if _customer_name = customer_name
      input_html_options[:data][:"selected-option-text"] = _customer_name
    end

    super
  end

  private

  def customer_name
    CustomerRecording
      .where(company: template.current_company, id: customer_recording_id)
      .pluck(:customer_name)
      .first
  end

  def customer_recording_id
    object.send(attribute_name)
  end
end
