class CustomerBillingConfiguration < ActiveRecord::Base
  belongs_to :customer_recording, required: true
  has_one :company, through: :customer_recording
  has_many :automated_report_requests, as: :parent

  scope :enabled, -> { where(disabled_at: nil) }

  after_initialize do |configuration|
    configuration.schedule_type ||= "day_interval"
  end

  validates :schedule_type, presence: true
  validates :day_interval, presence: true, if: :enabled?
  validates :day_interval, numericality: { only_integer: true, greater_than: 0 }

  after_save :schedule_billing

  class << self
    def edit_for_customer_recording(customer_recording)
      find_by(customer_recording: customer_recording) || new(customer_recording: customer_recording, disabled_at: Time.now)
    end

    def update_for_customer_recording(customer_recording, params: {})
      configuration = edit_for_customer_recording(customer_recording)
      configuration.assign_attributes(params)
      configuration.save

      configuration
    end
  end

  def auto_scheduled?
    %w(day_interval).include?(schedule_type)
  end

  def enabled
    disabled_at.nil?
  end

  alias_method :enabled?, :enabled

  def enabled=(value)
    if ["1", true].include?(value)
      self.disabled_at = nil
    else
      self.disabled_at = Time.now
    end
  end

  def disabled
    !enabled
  end

  alias_method :disabled?, :disabled

  def day_interval
    schedule_params["day_interval"] if schedule_params
  end

  def day_interval=(value)
    self.schedule_params ||= {}
    schedule_params["day_interval"] = begin
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end
  end

  def handle_report_request!(report_request)
    CustomerBilling.perform!(configuration: self, report_request: report_request)
  end

  def schedule_billing
    if disabled?
      automated_report_requests.unhandled.delete_all
      return true
    end

    already_scheduled_report_requests = automated_report_requests.unhandled.scheduled

    already_scheduled_report_requests_to_update =
      already_scheduled_report_requests.select do |report_request|
        # If the day interval has changed we need to change the report request as well
        report_request.parent_params["schedule_type"] == "day_interval" && (report_request.parent_params["schedule_params"].try(:[], "day_interval") != day_interval)
      end

    if already_scheduled_report_requests.size > 0
      already_scheduled_report_requests_to_update.each do |report_request|
        report_request.update!(parent_params: build_parent_params, run_at: calculate_run_at(from: report_request.created_at))
      end
    else
      schedule_next_billing!
    end
  end

  def schedule_next_billing_from_report_request!(report_request)
    if day_interval.present?
      regular_next_run_at = calculate_run_at(from: report_request.run_at)
      next_run_at = regular_next_run_at > Time.zone.now ? regular_next_run_at : calculate_run_at
      automated_report_requests.create!(parent_params: build_parent_params, run_at: next_run_at)
    else
      raise "Cannot schedule next billing when `day_interval` is not set"
    end
  end

  private

  def schedule_next_billing!
    if day_interval.present?
      automated_report_requests.create!(parent_params: build_parent_params, run_at: calculate_run_at)
    else
      raise "Cannot schedule next billing when `day_interval` is not set"
    end
  end

  def build_parent_params
    {
      "schedule_type" => schedule_type,
      "schedule_params" => schedule_params,
    }
  end

  def calculate_run_at(from: nil)
    from ||= Time.zone.now.change(min: 0, sec: 0)
    from + day_interval.days
  end
end
