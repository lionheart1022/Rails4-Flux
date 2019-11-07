class FakeTextInput < SimpleForm::Inputs::TextInput
  # This method only create a basic textarea without reading any value from object
  # From https://github.com/plataformatec/simple_form/wiki/Create-a-fake-input-that-does-NOT-read-attributes
  # Usage: <%= f.input :agreement, as: :fake_text %>
  def input(wrapper_options)
    template.text_area_tag(attribute_name, nil, input_html_options)
  end
end
