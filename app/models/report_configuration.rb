class ReportConfiguration < ActiveRecord::Base
  belongs_to :company, required: true
end
