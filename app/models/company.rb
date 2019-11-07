class Company < ActiveRecord::Base
  has_one  :address, class_name: 'Contact', as: :reference
  has_one  :shipment_export_setting, as: :owner
  has_many :shipment_exports, as: :owner

  has_many :users, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :carriers
  has_many :carrier_products
  has_many :customer_carrier_products, through: :carrier_products
  has_one  :asset_logo, as: :assetable, dependent: :destroy
  has_many :asset_company, as: :assetable, dependent: :destroy
  has_many :from_entity_relations, as: :from_reference, class_name: 'EntityRelation'
  has_many :to_entity_relations, as: :to_reference, class_name: 'EntityRelation'
  has_one  :economic_setting
  has_many :customer_imports
  has_many :customer_recordings
  has_many :trucks
  has_many :reports
  has_many :draft_reports
  has_many :eod_manifests, as: :owner
  has_many :carrier_feedback_files
  has_many :gls_feedback_configurations

  has_many :address_books, as: :owner
  has_many :contacts, through: :address_books

  validates :initials, uniqueness: { case_sensitive: false, allow_nil: true }

  # file assets
  include S3Callback

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  after_commit :update_related_customer_recordings, on: [:update]

  def update_next_truck_number
    self.with_lock do
      self.increment!(:current_truck_number)
    end
    return self.current_truck_number
  end

  class << self
    # Create a regular company.
    #
    # This method will create a regular company which will get a relation to the special CargoFlux company.
    def create_direct_company!(*args, &block)
      company = nil

      transaction do
        company = create!(*args, &block)

        EntityRelation.create!(
          from_reference: CargofluxCompany.find!,
          to_reference: company,
          relation_type: EntityRelation::RelationTypes::DIRECT_COMPANY,
        )
      end

      company
    end

    # Create the special CargoFlux company.
    #
    # This method will create the special CargoFlux company. Only 1 CargoFlux company should exist.
    def create_cargoflux_company!(*args, &block)
      company = nil

      transaction do
        company = Company.create!(*args, &block)

        Permission.create!(company: company, permission: Permission::Types::CAN_MANAGE_COMPANIES)

        # Raise exception and roll back transaction if we now have several CargoFlux company records.
        CargofluxCompany.find!
      end

      company
    end

    def create_company(company_data: nil)
      company = self.new({
        name:                 company_data[:name],
        domain:               company_data[:domain],
        info_email:           company_data[:info_email],
        initials:             company_data[:initials],
        current_customer_id:  0,
        current_report_id:    0
      })

      Company.transaction do
        company.save!
      end

      return company
    rescue => e
      raise ModelError.new(e.message, company)
    end

    def update_external_accounting_number(company_id: nil, company_customer_id: nil, number: nil)
      er = EntityRelation.where(from_reference_id: company_id, from_reference_type: Company.to_s, to_reference_id: company_customer_id, to_reference_type: Company.to_s).first
      er = er.update!(external_accounting_number: number)
      return er
    end

    # Finders

    def autocomplete_search(company_name: nil)
      self.where("name ILIKE ?", "%#{company_name}%")
    end

    def all_users(company_id: nil)
      User.where(company_id: company_id).where(is_customer: false)
    end

    def find_company_with_domain(domain: nil)
      Company.where(domain: domain).first
    end

    def find_carrier_product_customers(company_id: nil)
      Company.joins("left join entity_relations on companies.id=entity_relations.to_reference_id").where("entity_relations.from_reference_type=? and entity_relations.from_reference_id=? and entity_relations.to_reference_type=? and entity_relations.relation_type=?", Company.to_s, company_id, Company.to_s, EntityRelation::RelationTypes::CARRIER_PRODUCT_CUSTOMER)
    end

    def find_carrier_product_customer(company_id: nil, customer_id: nil)
      Company.joins("left join entity_relations on companies.id=entity_relations.to_reference_id").where("entity_relations.from_reference_type=? and entity_relations.from_reference_id=? and entity_relations.to_reference_type=? and entity_relations.relation_type=?", Company.to_s, company_id, Company.to_s, EntityRelation::RelationTypes::CARRIER_PRODUCT_CUSTOMER).where(id: customer_id).first
    end

    def find_all_companies_buying_from_company(company_id: nil)
      company_ids = self
        .joins("LEFT JOIN entity_relations er ON companies.id = er.from_reference_id AND er.to_reference_type = 'Company'")
        .where("er.from_reference_id = ? AND er.to_reference_type = 'Company'", company_id)
        .select("er.to_reference_id")
        .map &:to_reference_id

      Company.where(id: company_ids)
    end

    def find_all_companies_not_buying_from_company(company_id: nil)
      companies_buying_from_company = find_all_companies_buying_from_company(company_id: company_id).map &:id
      Company.where.not(id: companies_buying_from_company).where('id <> ?', company_id)
    end

    def find_company(company_id: nil)
      self.where(id: company_id).first
    end

  end

  # INSTANCE API

  def address_for_edit
    address || Contact.new
  end

  def shipment_action_required_count
    Shipment.count_company_shipments_in_state(company_id: id, state: Shipment::States::CREATED)
  end

  def shipment_request_action_required_count
    ShipmentRequest.get_action_required_for_company_count(company_id: id)
  end

  def pickup_action_required_count
    Pickup.count_company_pickups_in_state(company_id: id, state: Pickup::States::CREATED)
  end

  def ferry_booking_enabled?
    CarrierProduct
      .find_all_enabled_company_carrier_products(company_id: id)
      .where(type: "ScandlinesCarrierProduct")
      .exists?
  end

  def ferry_routes_available?
    FerryRoute.for_company(self).exists?
  end

  def find_ferry_route(ferry_route_id)
    FerryRoute.find_for_company(company: self, ferry_route_id: ferry_route_id)
  end

  def update_next_customer_id_without_locking
    increment!(:current_customer_id)
    current_customer_id
  end

  def update_next_customer_id
    self.with_lock do
      self.increment!(:current_customer_id)
    end
    return self.current_customer_id
  end

  def update_next_report_id_without_locking
    increment!(:current_report_id)
    current_report_id
  end

  def update_next_report_id
    self.with_lock do
      self.increment!(:current_report_id)
    end
    return self.current_report_id
  end

  def create_or_update_logo_asset(filepath: nil, filename: nil, filetype: nil)
    asset = asset_logo || AssetLogo.new(assetable: self)

    Asset.transaction do
      s3_copy_file_between_buckets(asset: asset, filepath: filepath, filename: filename)
    end

    return asset
  rescue => e
    raise ModelError.new(e.message, asset)
  end

  def create_asset_company(filepath: nil, filename: nil, filetype: nil, description: nil)
    asset = AssetCompany.new(assetable: self, description: description)

    Asset.transaction do
      s3_copy_file_between_buckets(asset: asset, filepath: filepath, filename: filename)
    end

    return asset
  rescue => e
    raise Shipment::Errors::CreateAwbAssetException.new(e.message)
  end

  def can_use_economic?
    addon_enabled?("economic")
  end

  def can_book_pickup?
    addon_enabled?("pickup")
  end

  def economic_v2_access?
    EconomicAccess.active.where(owner: self).exists?
  end

  def action_mailer_url_host
    if domain.present?
      domain
    else
      ActionMailer::Base.default_url_options[:host]
    end
  end

  def action_mailer_from_email
    info_email.presence || ActionMailer::Base.default[:from]
  end

  def has_in_progress_customer_import?
    customer_imports.in_progress.exists?
  end

  def add_carrier_product_customer!(carrier_product_customer)
    ActiveRecord::Base.transaction do
      entity_relation = EntityRelation.find_or_create_by!(from_reference: self, to_reference: carrier_product_customer, relation_type: EntityRelation::RelationTypes::CARRIER_PRODUCT_CUSTOMER)

      customer_recording = CustomerRecordings::CarrierProductCustomer.find_or_initialize_by(company: self, recordable: carrier_product_customer)
      customer_recording.disabled_at = nil
      customer_recording.save!
    end

    true
  end

  def create_customer!(*args, &block)
    customer = nil

    with_lock do
      customer = customers.new(*args, &block)
      customer.customer_id = update_next_customer_id_without_locking
      customer.save!

      customer_recording = CustomerRecordings::Customer.find_or_initialize_by(company: self, recordable: customer)
      customer_recording.disabled_at = nil
      customer_recording.save!
    end

    customer
  end

  def find_carrier_product_customer(carrier_product_customer_id)
    entity_relation = EntityRelation.find_by(from_reference: self, to_reference_type: "Company", to_reference_id: carrier_product_customer_id, relation_type: EntityRelation::RelationTypes::CARRIER_PRODUCT_CUSTOMER)
    Company.find(entity_relation.to_reference_id)
  end

  def find_carrier_product_customer_recording(carrier_product_customer)
    customer_recordings.enabled.find_by!(recordable: carrier_product_customer)
  end

  def find_customer(customer_id)
    customers.find(customer_id)
  end

  def find_customer_recording(customer)
    customer_recordings.enabled.find_by!(recordable: customer)
  end

  def create_report!(*args, &block)
    report = nil

    with_lock do
      report = reports.new(*args, &block)
      report.report_id = update_next_report_id_without_locking
      report.save!
    end

    report
  end

  def create_eod_manifest!(*args, &block)
    eod_manifest = nil

    transaction do
      counter = ScopedCounters::EODManifest.find_or_create_by!(owner: self)
      counter.with_lock do
        counter.increment!(:value)
        next_scoped_id = counter.value

        eod_manifest = eod_manifests.new(*args, &block)
        eod_manifest.owner_scoped_id = next_scoped_id
        eod_manifest.save!
      end
    end

    eod_manifest
  end

  def add_contact_to_address_book!(*args, &block)
    contact = nil

    transaction do
      address_book = address_books.find_or_create_by!({})
      contact = address_book.contacts.create!(*args, &block)
    end

    contact
  end

  def autocomplete_contacts(term)
    address_book = address_books.first

    if address_book
      address_book.contacts.autocomplete_search(company_name: term)
    else
      Contact.none
    end
  end

  def addon_enabled?(identifier)
    Addon
      .scope_by_identifier(identifier)
      .active
      .where(company: self)
      .exists?
  end

  def enable_addon!(identifier)
    Addon
      .scope_by_identifier(identifier)
      .active
      .find_or_create_by!(company: self)
  end

  def disable_addon!(identifier)
    Addon
      .scope_by_identifier(identifier)
      .active
      .where(company: self)
      .update_all(deleted_at: Time.zone.now)
  end

  def list_enabled_carriers
    ::Carrier
      .find_enabled_company_carriers(company_id: id)
      .includes(:carrier)
      .sort_by { |c| c.owner_carrier.company_id }
  end

  def find_enabled_carrier(carrier_id)
    ::Carrier
      .find_enabled_company_carriers(company_id: id)
      .find(carrier_id)
  end

  def all_carrier_products(carrier:)
    ::CarrierProduct
      .find_enabled_company_carrier_products(company_id: id, carrier_id: carrier.id)
      .sort_by { |p| p.name.downcase }
  end

  def all_company_users
    User
      .where(company_id: id)
      .where(is_customer: false)
  end

  def find_company_user(user_id, not_user_id: nil)
    all_company_users.where.not(id: not_user_id).find(user_id)
  end

  def shipment_export_setting_for_editing
    if shipment_export_setting
      shipment_export_setting
    else
      ShipmentExportSetting.new(owner: self)
    end
  end

  private

  def update_related_customer_recordings
    CustomerRecording.where(recordable: self).each(&:save)
  end
end
