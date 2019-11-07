class PickupMailer < CargofluxMailer
  def pickup_created_email(user: nil, customer: nil, company: nil, pickup: nil)
    @user     = user
    @customer = customer
    @company  = company
    @pickup   = pickup

    mail(from: company_from_email(company), to: user.email, subject: "#{@customer.name} - Pickup created") if @user.email_settings.pickup_create
  end

  def pickup_booked_email(user: nil, customer: nil, company: nil, pickup: nil)
    @user     = user
    @customer = customer
    @company  = company
    @pickup   = pickup

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Pickup booked") if @user.email_settings.pickup_book
  end

  def pickup_picked_up_email(user: nil, customer: nil, company: nil, pickup: nil)
    @user     = user
    @customer = customer
    @company  = company
    @pickup   = pickup

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Pickup picked up") if @user.email_settings.pickup_pickup
  end

  def pickup_problem_reported_email(user: nil, customer: nil, company: nil, pickup: nil)
    @user     = user
    @customer = customer
    @company  = company
    @pickup   = pickup

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Pickup problem") if @user.email_settings.pickup_problem
  end

  def pickup_cancelled_email(user: nil, customer: nil, company: nil, pickup: nil)
    @user     = user
    @customer = customer
    @company  = company
    @pickup   = pickup

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Pickup cancelled") if @user.email_settings.pickup_cancel
  end

  def pickup_commented_email(user: nil, customer: nil, company: nil, pickup: nil)
    @user     = user
    @customer = customer
    @company  = company
    @pickup   = pickup

    mail(from: company_from_email(company), to: user.email, subject: "#{@company.name} - Pickup commented") if @user.email_settings.pickup_comment
  end
end
