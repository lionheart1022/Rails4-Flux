class Asset < ActiveRecord::Base
  belongs_to :assetable, :polymorphic => true
  belongs_to :creator, polymorphic: true

  before_validation :generate_token, on: :create
  validates :token, presence: true, uniqueness: { case_sensitive: false }

  class << self

    def pdf_mimetypes
      ['application/pdf', 'application/x-pdf', 'applications/vnd.pdf']
    end

    def document_memetypes
      ['application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
    end

    def excel_memetypes
      ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel']
    end

    def image_mimetypes
      ['image/jpeg', 'image/png']
    end

    def text_mimetypes
      ['text/plain']
    end

    def html_mimetypes
      ['text/html']
    end

    def allowed_mimetypes
      pdf_mimetypes + document_memetypes + excel_memetypes + image_mimetypes
    end

    # Finders
    #

    def find_shipment_asset(shipment_id: nil, asset_id: nil)
      self.joins("LEFT JOIN shipments ON shipments.id = assets.assetable_id AND assets.assetable_type = 'Shipment'")
        .where('shipments.id = ? AND assets.id = ?', shipment_id, asset_id).readonly(false).first
    end

    def find_creator_or_not_private_assets(shipment_id: nil, creator_id: nil, creator_type: nil)
      self.joins("LEFT JOIN shipments ON shipments.id = assets.assetable_id AND assets.assetable_type = 'Shipment'")
        .where("(assets.type = 'AssetOther' AND assets.assetable_id = ?) AND ((private = false) OR (creator_id = ? AND creator_type = ?))", shipment_id, creator_id, creator_type)
    end

    def find_company_terms_and_condition_assets(company_id: nil)
      self.joins("LEFT JOIN companies ON companies.id = assets.assetable_id AND assets.assetable_type = 'Company'")
        .where("companies.id = ? AND assets.type = 'AssetCompany'", company_id)
    end

    def find_company_terms_and_condition_asset(company_id: nil, asset_id: nil)
      self.find_company_terms_and_condition_assets(company_id: company_id).where(id: asset_id).first
    end

  end

  def self.is_pdf?(filetype)
    self.pdf_mimetypes.include?(filetype)
  end

  protected

  def generate_token
    self.token = SecureRandom.uuid.parameterize if self.token.nil?
  end
end
