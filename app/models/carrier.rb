class Carrier < ActiveRecord::Base
  has_many :carrier_products, dependent: :destroy
  belongs_to :company
  belongs_to :carrier

  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: [:company_id, :carrier_id] }

  accepts_nested_attributes_for :carrier_products

  class << self

    def create_carrier(company_id: nil, name: nil)
      carrier = self.new({
        company_id: company_id,
        name: name,
      })

      Carrier.transaction do
        carrier.save!
      end

      return carrier
    rescue => e
      raise ModelError.new(e.message, carrier)
    end

    def create_carrier_from_existing_carrier(company_id: nil, existing_carrier_id: nil)
      existing_carrier = Carrier.find(existing_carrier_id)
      carrier = self.new({
        company_id: company_id,
        carrier_id: existing_carrier.id,
        type: existing_carrier.type
      })

      Carrier.transaction do
        carrier.save!
      end

      return carrier
    rescue => e
      raise ModelError.new(e.message, carrier)
    end

    # Finders

    def find_company_carriers(company_id: nil)
      self.where(company_id: company_id)
    end

    def find_enabled_company_carriers(company_id: nil)
      self
        .where('carriers.id IN (WITH RECURSIVE tree(id, parent_id) AS (
                     SELECT c.id, c.carrier_id
                     FROM carriers c
                     WHERE NOT c.disabled AND c.company_id = ?
                   UNION ALL
                     SELECT c.id, c.carrier_id
                     FROM carriers c
                     JOIN tree ON c.carrier_id = tree.id
                     WHERE NOT c.disabled AND c.company_id = ?)
                    SELECT id FROM tree)', company_id, company_id)
        .where(company_id: company_id)
    end

    def find_company_carrier(company_id: nil, carrier_id: nil)
      self.find_company_carriers(company_id: company_id).where(id: carrier_id).first
    end

    def find_enabled_customer_carriers(company_id: nil, customer_id: nil)
      customer_carrier_ids =
        CustomerCarrierProduct
        .includes(:carrier_product)
        .where(customer_id: customer_id, is_disabled: false, carrier_products: { is_disabled: false })
        .map { |customer_carrier_product| customer_carrier_product.carrier_product.carrier_id }
        .uniq

      self
        .find_enabled_company_carriers(company_id: company_id)
        .where(id: customer_carrier_ids)
    end

    def search_enabled_customer_carriers(company_id: nil, customer_id: nil, carrier_name: nil)
      customer_carrier_ids =
        CustomerCarrierProduct
        .includes(:carrier_product)
        .where(customer_id: customer_id, is_disabled: false, carrier_products: { is_disabled: false })
        .map { |customer_carrier_product| customer_carrier_product.carrier_product.carrier_id }
        .uniq

      self
        .autocomplete_search(company_id: company_id, carrier_name: carrier_name)
        .where(id: customer_carrier_ids)
    end

    def find_customer_company_carriers(company_id: nil, customer_company_id: nil)
      carriers = self.where("carriers.carrier_id IN
                 (WITH RECURSIVE tree(id) AS (
                    SELECT c.id, c.name FROM carriers c
                    WHERE c.company_id = ?
                    UNION ALL
                      SELECT c.id, c.name FROM carriers c JOIN tree ON c.carrier_id = tree.id)
                  SELECT id FROM tree) AND company_id = ?", company_id, customer_company_id)
    end

    def autocomplete_search(company_id: nil, carrier_name: nil)
      recurse_carrier_names_sql = <<-SQL.squish
        WITH RECURSIVE r_carriers(id, type, name, ancestor_carrier_id) AS (
          SELECT id, type, name, carrier_id
          FROM carriers
          WHERE company_id = :company_id

          UNION ALL

          SELECT r_carriers.id, r_carriers.type, carriers.name, carriers.carrier_id
          FROM carriers, r_carriers
          WHERE carriers.id = r_carriers.ancestor_carrier_id
        )
        SELECT r_carriers.id
        FROM r_carriers
        WHERE name ILIKE :search_term OR type ILIKE :search_term
      SQL

      self.where("carriers.id IN (#{recurse_carrier_names_sql})", company_id: company_id, search_term: "%#{carrier_name}%")
    end

    def enabled
      self.where(disabled: false)
    end

  end

  # INSTANCE API

  def name
    # if referencing a predefined carrier then name is taken from there
    if (self.carrier.present? && read_attribute(:name).nil?)
      self.carrier.name
    else
      read_attribute(:name)
    end
  end

  def first_unlocked_product_in_owner_chain
    owner_chain = self.owner_carrier_product_chain(include_self: true)
    configured_product = owner_chain.detect { |cp| cp.state == CarrierProduct::States::UNLOCKED_FOR_CONFIGURING }
  end

  def carrier_responsible
    self.first_unlocked_carrier_in_owner_chain.company
  end

  def owner_carrier
    self.carrier.nil? ? self : self.carrier
  end

  def is_locked_for_editing?
    # if referencing a parent carrier then this record is locked for editing
    self.carrier.nil? ? false : true
  end

  def can_edit_surcharges?
    if (a_carrier_product = carrier_products.first)
      a_carrier_product.state == CarrierProduct::States::UNLOCKED_FOR_CONFIGURING
    else
      true
    end
  end

  def supports_override_credentials?
    false
  end

  def override_credentials_class
    nil
  end

  def overrides_credentials_for_customer?(customer)
    if credential = override_credentials_class.find_by(target: self, owner: customer)
      credential.has_any_present_credential_fields?
    else
      false
    end
  end

  def bulk_update_surcharges(surcharges_attributes, current_user: nil)
    transaction do
      (surcharges_attributes || {}).each do |_key, surcharge_attrs|
        surcharge_id = surcharge_attrs.delete(:id)
        predefined_type = surcharge_attrs.delete(:predefined_type)

        surcharge_for_carrier = SurchargeOnCarrier.for_bulk_update(self, id: surcharge_id, predefined_type: predefined_type)
        surcharge_for_carrier.assign_attributes(surcharge_attrs)
        surcharge_for_carrier.created_by = current_user
        surcharge_for_carrier.carrier = self

        surcharge_for_carrier.surcharge.save!
        surcharge_for_carrier.save!
      end
    end

    true
  end

  def list_all_surcharges
    surcharges = default_and_carrier_specific_surcharges

    surcharges + SurchargeOnCarrier.where(carrier: self).order(:id).where.not(id: surcharges.map(&:id)).to_a
  end

  def default_and_carrier_specific_surcharges
    default_surcharges + carrier_specific_surcharges
  end

  def default_surcharges
    [
      find_fuel_charge,
      find_residential_surcharge,
    ]
  end

  def carrier_specific_surcharges
    []
  end

  def enabled_surcharges
    list_all_surcharges.select { |surcharge| surcharge.persisted? && surcharge.enabled? }
  end

  def find_fuel_charge
    SurchargeOnCarrier.all.includes(:surcharge).find_by(carrier: self, surcharges: { type: "FuelSurcharge" }) ||
      SurchargeOnCarrier.new(carrier: self, surcharge: FuelSurcharge.new(description: "Fuel", calculation_method: "price_percentage"), enabled: false, predefined_type: "fuel")
  end

  def find_residential_surcharge
    SurchargeOnCarrier.all.includes(:surcharge).find_by(carrier: self, surcharges: { type: "ResidentialSurcharge" }) ||
      SurchargeOnCarrier.new(carrier: self, surcharge: ResidentialSurcharge.new(description: "Residential delivery", calculation_method: "price_fixed"), enabled: false, predefined_type: "residential")
  end

  def build_surcharges_from_config(carrier_identifier)
    CarrierConfig.surcharges_for_carrier(carrier_identifier).map do |predefined_type, surcharge_props|
      surcharge_type = surcharge_props.fetch(:klass)

      surcharge_on_carrier   = SurchargeOnCarrier.all.where(carrier: self).includes(:surcharge).find_by(surcharges: { type: surcharge_type })
      surcharge_on_carrier ||= SurchargeOnCarrier.new(carrier: self, surcharge: Surcharge.build_surcharge_by_predefined_type(predefined_type), enabled: false, predefined_type: predefined_type)

      surcharge_on_carrier
    end
  end

  def suffixed_name
    cp = self.carrier_products.first
    string = self.name
    if cp
      owner = cp.product_responsible
      string = "#{string} (#{owner.initials})" if owner.initials
    end

    string
  end

  def product_responsible
    if carrier_product = carrier_products.first
      carrier_product.product_responsible
    end
  end
end
