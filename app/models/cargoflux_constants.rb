module CargofluxConstants
  module Group
    NONE          = 'group_none'
    CUSTOMER      = 'group_customer'
    COMPANY       = 'group_company'
    MONTHS        = 'group_months'
    STATE         = 'group_state'
    CUSTOMER_TYPE = 'group_customer_type'
  end

  module Sort
    DATE_ASC  = 'sort_date_asc'
    DATE_DESC = 'sort_date_desc'
  end

  module Filter
    CARRIER_ID                  = 'filter_carrier_id'
    NOT_IN_MANIFEST             = 'filter_not_in_manifest'
    CUSTOMER_ID                 = 'filter_customer_id'
    STATE                       = 'filter_state'
    SHIPMENT_ID                 = 'filter_shipment_id'
    NOT_IN_REPORT               = 'filter_not_in_report'
    HAS_BEEN_BOOKED             = 'filter_has_been_booked'
    CUSTOMER_TYPE               = 'filter_customer_type'
    COMPANY_ID                  = 'filter_company_id'
    NOT_CANCELED                = 'filter_not_canceled'
    HAS_BEEN_BOOKED_OR_IN_STATE = 'filter_has_been_booked_or_in_state'
    ACTIVE_OR_IN_STATE          = 'filter_active_or_in_state'
    ACTIVE                      = 'filter_active'
    RANGE_START                 = 'filter_range_start'
    RANGE_END                   = 'filter_range_end'
  end

  module CustomerTypes
    DIRECT_CUSTOMERS          = 'direct_customers'
    COMPANY_CUSTOMERS         = 'company_customers'
    CARRIER_PRODUCT_CUSTOMERS = 'carrier_product_customers'
  end
end
