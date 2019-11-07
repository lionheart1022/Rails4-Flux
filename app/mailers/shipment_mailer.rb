class ShipmentMailer < CargofluxMailer
  def shipment_created_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@customer.name} - Shipment created") if @user.email_settings.create && !@shipment.requested?
  end

  def shipment_booked_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Shipment booked") if @user.email_settings.book
  end

  def shipment_booked_with_warnings_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Shipment booked with warnings") if @user.email_settings.book
  end

  def shipment_autobooked_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@customer.name} - Shipment auto booked") if @user.email_settings.book
  end

  def shipment_autobooked_with_warnings_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@customer.name} - Shipment auto booked with warnings") if @user.email_settings.autobook_with_warnings
  end

  def shipment_shipped_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Shipment shipped") if @user.email_settings.ship
  end

  def shipment_delivered_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Shipment delivered") if @user.email_settings.delivered
  end

  def shipment_problem_reported_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Shipment problem") if @user.email_settings.problem
  end

  def shipment_autobook_problem_reported_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@customer.name} - Shipment auto book problem") if @user.email_settings.problem
  end

  def shipment_cancelled_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Shipment cancelled") if @user.email_settings.cancel
  end

  def shipment_commented_email(user: nil, customer: nil, company: nil, shipment: nil)
    @user     = user
    @customer = customer
    @company  = company
    @shipment = shipment

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Shipment commented") if @user.email_settings.comment
  end
end
