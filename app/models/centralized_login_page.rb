class CentralizedLoginPage < ActiveRecord::Base
  self.table_name = "central_login_pages"

  belongs_to :primary_item, class_name: "CentralizedLoginPageItem"
  has_one :primary_company, through: :primary_item, source: :company

  has_many :items, class_name: "CentralizedLoginPageItem", foreign_key: "page_id"
  has_many :companies, through: :items

  class << self
    def easy_create!(domain:, title:, companies:)
      page = nil

      transaction do
        page = create!(domain: domain, title: title)

        companies.each_with_index do |company, index|
          page.items.create!(company: company, sort_order: index)
        end

        # Mark the first company as being the primary one
        page.update!(primary_item: page.items.order(:id).first)
      end

      page
    end
  end
end
