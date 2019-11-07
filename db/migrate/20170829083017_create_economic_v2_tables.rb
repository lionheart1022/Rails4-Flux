class CreateEconomicV2Tables < ActiveRecord::Migration
  def change
    create_table :economic_accesses do |t|
      t.datetime :created_at, null: false
      t.datetime :revoked_at

      t.references :owner, polymorphic: true, null: false
      t.string :agreement_grant_token
      t.boolean :active, null: false, default: true
      t.json :self_response
    end

    create_table :economic_product_requests do |t|
      t.datetime :created_at, null: false
      t.datetime :fetched_at

      t.references :access, null: false
    end

    create_table :economic_products do |t|
      t.timestamps null: false

      t.references :access, null: false
      t.string :number, null: false
      t.string :name
      t.json :all_params
      t.boolean :no_longer_available, null: false, default: false

      t.index [:access_id, :number], unique: true
    end

    create_table :economic_product_mappings do |t|
      t.timestamps null: false
      t.references :owner, polymorphic: true, null: false
      t.references :item, polymorphic: true, null: false
      t.string :product_number_incl_vat
      t.string :product_name_incl_vat
      t.string :product_number_excl_vat
      t.string :product_name_excl_vat
    end

    create_table :economic_invoices do |t|
      t.timestamps null: false
      t.references :parent, polymorphic: true, null: false
      t.references :seller, polymorphic: true, null: false
      t.references :buyer, polymorphic: true, null: false
      t.string :currency
      t.string :external_accounting_number
      t.boolean :ready, default: false
      t.datetime :job_enqueued_at
      t.datetime :http_request_sent_at
      t.boolean :http_request_succeeded
      t.boolean :http_request_failed
    end

    create_table :economic_invoice_shipments do |t|
      t.references :invoice, null: false
      t.references :shipment, null: false
    end

    create_table :economic_invoice_lines do |t|
      t.timestamps null: false
      t.references :invoice, null: false
      t.json :payload
    end
  end
end
