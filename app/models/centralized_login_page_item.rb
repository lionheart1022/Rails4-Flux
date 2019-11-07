class CentralizedLoginPageItem < ActiveRecord::Base
  self.table_name = "central_login_page_items"

  belongs_to :page, required: true, class_name: "CentralizedLoginPage"
  belongs_to :company, required: true

  scope :ordered, -> { order(sort_order: :asc) }

  def company_name
    company.name
  end
end
