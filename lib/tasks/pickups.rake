namespace :pickups do
  desc "Archive auto-pickups older than n (default: 7) days"
  task :archive_auto, [:days] => [:environment] do |t, args|
    n_days = 7 # Default

    if args[:days].present?
      begin
        n_days = Integer(args[:days])
      rescue ArgumentError
        abort "Invalid `days` argument (#{args[:days].inspect})"
      end
    end

    if n_days < 1
      abort "`days` argument needs to be >= 1"
    end

    outdated_auto_pickups = Pickup.auto.outdated(n_days.days.ago)
    pickups_to_archive = outdated_auto_pickups.where(state: Pickup::States::BOOKED)
    pickups_to_cancel = outdated_auto_pickups.where(state: Pickup::States::PROBLEM)

    pickups_to_archive.each do |pickup|
      pickup.pickup(comment: "Auto-pickups older than #{n_days} #{'day'.pluralize(n_days)} will automatically be marked as picked up")
    end

    pickups_to_cancel.each do |pickup|
      pickup.cancel(comment: "Failed auto-pickups older than #{n_days} #{'day'.pluralize(n_days)} will automatically be marked as cancelled")
    end
  end
end
