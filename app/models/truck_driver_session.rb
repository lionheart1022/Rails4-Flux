class TruckDriverSession < TokenSession
  alias_method :truck_driver, :sessionable

  def user_email
    truck_driver.user.email if truck_driver.user
  end
end
