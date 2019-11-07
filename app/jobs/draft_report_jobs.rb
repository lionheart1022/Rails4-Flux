module DraftReportJobs
  class GenerateShipmentCollection < ActiveJob::Base
    queue_as :reports

    def perform(draft_report_id)
      draft_report = DraftReport.find(draft_report_id)
      draft_report.generate_shipment_collection!
    end
  end

  class GenerateReport < ActiveJob::Base
    queue_as :reports

    def perform(draft_report_id)
      draft_report = DraftReport.find(draft_report_id)
      draft_report.generate_report!
    end
  end
end
