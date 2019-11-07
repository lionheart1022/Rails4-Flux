class APIRequestError < StandardError
  attr_reader :code, :message

  module Codes
    SHIPMENT_MISSING_OR_NOT_FOUND       = 'CF-API-001'
    CALLBACK_MISSING                    = 'CF-API-002'
    INVALID_PRODUCT_CODE                = 'CF-API-003'
    CANNOT_RETRY_ALREADY_BOOKED         = 'CF-API-004'
    NO_ACCESS_TO_PRODUCT                = 'CF-API-005'
    INVALID_PACKAGE_DIMENSIONS          = 'CF-API-006'
    INVALID_SHIPPING_DATE               = 'CF-API-007'
    INVALID_CUSTOMS_INFORMATION         = 'CF-API-008'
    RETURN_LABEL_NOT_SUPPORTED          = 'CF-API-009'
    DELIVERY_INSTRUCTIONS_NOT_SUPPORTED = 'CF-API-010'
    DGR_NOT_ALLOWED                     = 'CF-API-011'
    DGR_INVALID_IDENTIFIER              = 'CF-API-012'
    DGR_NOT_ENABLED_OPTION_GIVEN        = 'CF-API-013'
    AUTO_PICKUP_NOT_AVAILABLE           = 'CF-API-014'
  end

  module Messages
    SHIPMENT_MISSING_OR_NOT_FOUND       = 'invalid or missing shipment_id'
    CALLBACK_MISSING                    = 'callback_url not specified'
    INVALID_PRODUCT_CODE                = 'invalid or missing product_code'
    CANNOT_RETRY_ALREADY_BOOKED         = 'cannot retry shipment that has already been booked'
    NO_ACCESS_TO_PRODUCT                = 'you don\'t have access to this product'
    INVALID_PACKAGE_DIMENSIONS          = 'package_dimensions not formatted properly'
    INVALID_SHIPPING_DATE               = 'shipping_date not formatted properly'
    INVALID_CUSTOMS_INFORMATION         = 'invalid or missing customs information'
    RETURN_LABEL_NOT_SUPPORTED          = 'Selected product does not support return labels'
    DELIVERY_INSTRUCTIONS_NOT_SUPPORTED = 'Selected product does not support delivery instructions'
    DGR_NOT_ALLOWED                     = 'This account is not allowed to book DGR shipments'
    DGR_INVALID_IDENTIFIER              = 'Unsupported DGR identifier has been used'
    DGR_NOT_ENABLED_OPTION_GIVEN        = 'DGR identifier has been given but `enabled` flag is not set'
    AUTO_PICKUP_NOT_AVAILABLE           = 'Auto-pickup is not possible'
  end

  def initialize(code: nil, message: nil)
    @code    = code
    @message = message
  end
end
