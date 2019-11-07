class ShipmentRequestMailer < CargofluxMailer
  def shipment_request_created_email(user: nil, customer: nil, company: nil, shipment: nil, shipment_request: nil)
    @shipment_request = shipment_request
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@customer.name} - RFQ created") if @user.email_settings.rfq_create
  end

  def shipment_request_proposed_email(user: nil, customer: nil, company: nil, shipment: nil, shipment_request: nil)
    @shipment_request = shipment_request
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - RFQ proposed") if @user.email_settings.rfq_propose
  end

  def shipment_request_accepted_email(user: nil, customer: nil, company: nil, shipment: nil, shipment_request: nil)
    @shipment_request = shipment_request
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@customer.name} - RFQ accepted") if @user.email_settings.rfq_accept
  end

  def shipment_request_declined_email(user: nil, customer: nil, company: nil, shipment: nil, shipment_request: nil)
    @shipment_request = shipment_request
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@customer.name} - RFQ declined") if @user.email_settings.rfq_decline
  end

  def shipment_request_booked_email(user: nil, customer: nil, company: nil, shipment: nil, shipment_request: nil)
    @shipment_request = shipment_request
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - RFQ booked") if @user.email_settings.rfq_book
  end

  def shipment_request_canceled_email(user: nil, customer: nil, company: nil, shipment: nil, is_customer: nil, shipment_request: nil)
    @is_customer      = is_customer
    @shipment_request = shipment_request
    @user             = user
    @customer         = customer
    @company          = company
    @shipment         = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - RFQ canceled") if @user.email_settings.rfq_cancel
  end
end
