class EconomicInvoiceExportRecord < ActiveRecord::Base
  self.table_name = "economic_invoice_exports"

  belongs_to :parent, polymorphic: true, required: true

  scope :in_progress, -> { where(finished_at: nil) }

  def in_progress?
    finished_at.nil?
  end

  def finished?
    !in_progress?
  end

  def generate_and_create_invoices!
    return if finished?

    if parent.is_a?(Report)
      transaction do
        EconomicInvoiceExport.create_from_report!(parent)
        touch(:finished_at)
      end
    else
      raise "Only `parent` reports are supported"
    end
  end
end
