module GroupSortFilter
  extend ActiveSupport::Concern

  class Result
    attr_reader :group, :sort, :filters, :paginated_result, :result

    def initialize(group: nil, sort: nil, filters: nil, paginated_result: nil, result: nil)
      @group            = group
      @sort             = sort
      @filters          = filters
      @paginated_result = paginated_result
      @result           = result
    end
  end

  class DataGroup
    attr_reader :name, :reference, :data

    def initialize(name: nil, reference: nil, data: nil)
      @name       = name
      @reference  = reference
      @data       = data
    end
  end

  class Filter
    attr_reader :filter, :filter_value

    def initialize(filter: nil, filter_value: nil)
      @filter       = filter
      @filter_value = filter_value
    end
  end

  class Group
    attr_reader :type, :data

    def initialize(type: nil, data: nil)
      @type = type
      @data = data
    end
  end

  module ClassMethods

    # Applies grouping, sorting and filtering to a result set
    #
    # @return [GroupSortFilter::Result]
    def apply_group_sort_filter(current_company_id: nil, group: nil, sort: nil, filters: nil, page: nil)
      result           = self
      result           = self.apply_filters(filters: filters, current_company_id: current_company_id) if filters
      result           = result.apply_sort(sort) if sort
      paginated_result = page ? result.page(page) : result
      result           = paginated_result.apply_group(group) if group

      return GroupSortFilter::Result.new(group: group, sort: sort, filters: filters, paginated_result: paginated_result, result: result)
    end
  end
end

