class StatesGroupedByCountryInput < SimpleForm::Inputs::CollectionInput
  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.grouped_collection_select(
      attribute_name, # method
      StatesPerCountry.as_array, # collection
      :states, # group_method
      :country_code, # group_label_method
      :state_code, # option_key_method
      :full_state_name, # option_value_method
      input_options, # options
      merged_input_options, # html_options
    )
  end
end
