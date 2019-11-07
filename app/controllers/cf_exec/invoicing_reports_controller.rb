module CFExec
  class InvoicingReportsController < ExecController
    def show
      report_params = { month: params[:month], year: params[:year] }.reject { |_, value| value.blank? }
      @invoicing_report = InvoicingReportForm.new(report_params)

      respond_to do |format|
        format.html
        format.csv do
          render text: @invoicing_report.produce_csv, content_type: "text/plain"
        end
      end
    end

    private

    def active_nav
      case params[:action]
      when "show"
        [:invoicing, :report]
      end
    end

    class InvoicingReportForm
      include ActiveModel::Model

      attr_accessor :month
      attr_accessor :year

      def initialize(params = {})
        @today = Date.today

        self.month = @today.month
        self.year = @today.year

        super
      end

      def produce_csv
        invoicing_report = InvoicingReport.new(from: first_day_in_month, to: last_day_in_month)
        csv_string = invoicing_report.produce_csv
      end

      def first_day_in_month
        Date.new(Integer(year), Integer(month), 1)
      end

      def last_day_in_month
        first_day_in_month.end_of_month
      end

      def available_months
        (1..12).map do |month_index|
          OpenStruct.new(index: month_index, name: Date.new(@today.year, month_index, 1).strftime("%B"))
        end
      end

      def available_years
        ((@today.year - 3)..(@today.year)).map do |year|
          OpenStruct.new(index: year, name: year)
        end
      end
    end
  end
end
