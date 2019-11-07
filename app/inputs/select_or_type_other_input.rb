class SelectOrTypeOtherInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    collection = options.delete(:collection) || []

    if collection.any?
      add_html_options = {
        class: "string",
        data: { behavior: "select_or_type_other", collection: collection },
      }

      @builder.text_field(attribute_name, input_html_options.merge(add_html_options))
    else
      super
    end
  end
end
