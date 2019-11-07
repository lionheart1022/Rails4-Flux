class Shared::ListView

  class Filter
    attr_reader :filter, :filter_select_values, :filter_selected_value, :filter_placeholder

    def initialize(filter: nil, filter_select_values: nil, filter_selected_value: nil, filter_placeholder: nil)
      @filter                 = filter
      @filter_select_values   = filter_select_values
      @filter_selected_value  = filter_selected_value
      @filter_placeholder  = filter_placeholder
    end
  end

  class RangeFilter
    attr_reader :filter, :filter_value, :filter_label

    def initialize(filter: nil, filter_value: nil, filter_label: nil)
      @filter       = filter
      @filter_label       = filter_label
      @filter_value = filter_value
    end
  end

  attr_reader :main_view,
              :heading, :subheading, :no_results,
              :show_action, :current_company, :action_text, :action_url,
              :table_class_name, :table_columns_view,
              :table_content_view, :table_content_group_view,
              :is_grouped, :ungrouped_data, :data_groups, :paginated_data,
              :scope_group_values, :scope_sort_values, :range_filters, :search_filters, :scope_filters, :scope_url,
              :scope_group_selected_value, :scope_sort_selected_value, :carrier_products, :companies

  def initialize(heading: nil, subheading: nil, no_results: nil,
                 show_action: nil, current_company: nil, action_text: nil, action_url: nil,
                 table_class_name: nil, table_columns_view: nil,
                 table_content_view: nil, range_filters: [], table_content_group_view: nil,
                 scope_group_values: nil, search_filters: [], scope_filters: nil, scope_url: nil, data: nil, carrier_products: nil, companies: nil)

    @heading                  = heading
    @subheading               = subheading
    @no_results               = no_results
    @show_action              = show_action
    @current_company          = current_company
    @action_text              = action_text
    @action_url               = action_url
    @table_class_name         = table_class_name || "shipments"
    @table_columns_view       = table_columns_view
    @table_content_view       = table_content_view
    @table_content_group_view = table_content_group_view
    @scope_filters            = scope_filters
    @search_filters           = search_filters
    @range_filters            = range_filters
    @scope_url                = scope_url
    @data                     = data
    @carrier_products         = carrier_products
    @companies                = companies

    # Data
    @is_grouped     = data.group.type != CargofluxConstants::Group::NONE
    @ungrouped_data = data.result
    @data_groups    = data.result
    @paginated_data = data.paginated_result

    # Grouping, sorting, filtering
    setup_group_values(scope_group_values)
    setup_sort_values

    ## Selected values for scope selects
    @scope_group_selected_value = data.group.type
    @scope_sort_selected_value  = data.sort

    state_general
  end

  private

  def setup_group_values(scope_group_values)
    # Values for scope selects
    all_scope_group_values = {
      CargofluxConstants::Group::NONE           => ['No grouping',              CargofluxConstants::Group::NONE],
      CargofluxConstants::Group::CUSTOMER       => ['Grouped by customer',      CargofluxConstants::Group::CUSTOMER],
      CargofluxConstants::Group::CUSTOMER_TYPE  => ['Grouped by customer type', CargofluxConstants::Group::CUSTOMER_TYPE],
      CargofluxConstants::Group::COMPANY        => ['Grouped by company',       CargofluxConstants::Group::COMPANY],
      CargofluxConstants::Group::STATE          => ['Grouped by state',         CargofluxConstants::Group::STATE]
    }
    @scope_group_values = scope_group_values.map {|value| all_scope_group_values[value] }
  end

  def setup_sort_values
    @scope_sort_values = [
      ['Newest first', CargofluxConstants::Sort::DATE_DESC],
      ['Oldest first', CargofluxConstants::Sort::DATE_ASC]
    ]
  end

  def state_general
    @main_view = "components/shared/list_view"
  end
end
