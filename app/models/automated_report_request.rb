class AutomatedReportRequest < ActiveRecord::Base
  belongs_to :parent, polymorphic: true, required: true
  belongs_to :report, required: false

  scope :unhandled, -> { where(handled_at: nil) }
  scope :handled, -> { where.not(handled_at: nil) }
  scope :scheduled, -> { where.not(run_at: nil) }

  class << self
    def scheduled_to_run
      unhandled.where(arel_table[:run_at].lteq(Time.zone.now))
    end

    def handle_requests_scheduled_to_run!
      scheduled_to_run.each do |report_request|
        begin
          report_request.handle!
        rescue => e
          # If a report request fails (for whatever reason) it should not affect the other ones.
          ExceptionMonitoring.report_exception!(e, context: { report_request_id: report_request.id }, raise_in_environments: %w{test})
        end
      end
    end

    def build_report_success_result(report)
      HandleRequestResult.new(report, false)
    end

    def build_no_matching_shipments_result
      HandleRequestResult.new(nil, true, "no_matching_shipments")
    end
  end

  def handle!
    with_lock do
      result = parent.handle_report_request!(self)
      update!(
        report: result.report,
        skipped_report: result.skipped_report,
        skipped_report_reason: result.skipped_report_reason,
        handled_at: Time.zone.now,
      )
    end
  end

  HandleRequestResult = Struct.new(:report, :skipped_report, :skipped_report_reason)
end
