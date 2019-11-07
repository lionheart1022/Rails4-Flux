# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181116144806) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer  "company_id", null: false
    t.string   "type",       null: false
  end

  create_table "address_books", force: :cascade do |t|
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
  end

  create_table "advanced_price_line_items", force: :cascade do |t|
    t.integer  "advanced_price_id"
    t.string   "description",        limit: 255
    t.decimal  "cost_price_amount",              precision: 20, scale: 12
    t.decimal  "sales_price_amount",             precision: 20, scale: 12
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "times",                                                    default: 1
    t.text     "parameters"
    t.string   "price_type"
  end

  add_index "advanced_price_line_items", ["advanced_price_id"], name: "index_advanced_price_line_items_on_advanced_price_id", using: :btree

  create_table "advanced_prices", force: :cascade do |t|
    t.integer  "shipment_id"
    t.string   "cost_price_currency",  limit: 255
    t.string   "sales_price_currency", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "price_type",           limit: 255
    t.integer  "seller_id"
    t.integer  "buyer_id"
    t.string   "seller_type",          limit: 255
    t.string   "buyer_type",           limit: 255
  end

  add_index "advanced_prices", ["shipment_id"], name: "index_advanced_prices_on_shipment_id", using: :btree

  create_table "aggregate_shipment_statistic_changes", force: :cascade do |t|
    t.integer  "shipment_id", null: false
    t.datetime "handled_at"
  end

  add_index "aggregate_shipment_statistic_changes", ["handled_at"], name: "index_aggregate_shipment_statistic_changes_on_handled_at", using: :btree

  create_table "aggregate_shipment_statistics", force: :cascade do |t|
    t.date    "utc_from",                                                       null: false
    t.date    "utc_to",                                                         null: false
    t.string  "resolution",                                                     null: false
    t.boolean "aggr_values_ready",                              default: false, null: false
    t.boolean "needs_refresh",                                  default: false, null: false
    t.integer "company_id",                                                     null: false
    t.integer "customer_id"
    t.integer "carrier_id"
    t.string  "carrier_type"
    t.integer "carrier_product_id"
    t.string  "carrier_product_type"
    t.integer "total_no_of_packages"
    t.integer "total_no_of_shipments"
    t.decimal "total_weight",          precision: 20, scale: 3
    t.json    "total_cost"
    t.json    "total_revenue"
    t.integer "company_customer_id"
  end

  create_table "api_requests", force: :cascade do |t|
    t.string   "unique_id"
    t.integer  "shipment_id"
    t.string   "token"
    t.string   "callback_url"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "api_requests", ["shipment_id"], name: "index_api_requests_on_shipment_id", using: :btree

  create_table "assets", force: :cascade do |t|
    t.string   "type",                    limit: 255
    t.integer  "assetable_id"
    t.string   "assetable_type",          limit: 255
    t.string   "attachment_file_name",    limit: 255
    t.string   "attachment_content_type", limit: 255
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.string   "attachment_fingerprint",  limit: 255
    t.string   "token",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description",             limit: 255
    t.boolean  "private",                             default: false
    t.integer  "creator_id"
    t.string   "creator_type"
  end

  add_index "assets", ["assetable_id", "assetable_type"], name: "index_assets_on_assetable_id_and_assetable_type", using: :btree

  create_table "automated_report_requests", force: :cascade do |t|
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.datetime "handled_at"
    t.datetime "run_at"
    t.integer  "parent_id",             null: false
    t.string   "parent_type",           null: false
    t.json     "parent_params"
    t.integer  "report_id"
    t.boolean  "skipped_report"
    t.string   "skipped_report_reason"
  end

  create_table "carrier_feedback_configurations", force: :cascade do |t|
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "company_id",      null: false
    t.string   "type"
    t.integer  "latest_file_id"
    t.json     "credentials"
    t.json     "account_details"
    t.json     "file_data"
  end

  create_table "carrier_feedback_files", force: :cascade do |t|
    t.datetime "created_at",          null: false
    t.integer  "company_id",          null: false
    t.string   "type"
    t.binary   "file_contents"
    t.integer  "file_uploaded_by_id"
    t.string   "original_filename"
    t.string   "s3_object_key"
    t.datetime "parsed_at"
    t.integer  "configuration_id"
  end

  create_table "carrier_pickup_requests", force: :cascade do |t|
    t.datetime "created_at",             null: false
    t.datetime "handled_at"
    t.string   "type",                   null: false
    t.integer  "pickup_id",              null: false
    t.integer  "retries",    default: 0, null: false
    t.json     "params"
    t.json     "result"
  end

  create_table "carrier_product_autobook_requests", force: :cascade do |t|
    t.integer  "shipment_id"
    t.integer  "company_id"
    t.integer  "customer_id"
    t.string   "uuid",        limit: 255
    t.string   "state",       limit: 255
    t.text     "info"
    t.string   "type",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "data"
  end

  create_table "carrier_product_credentials", force: :cascade do |t|
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "target_id",         null: false
    t.string   "target_type",       null: false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "type"
    t.json     "credential_fields"
  end

  create_table "carrier_product_margin_configurations", force: :cascade do |t|
    t.datetime "created_at",          null: false
    t.integer  "created_by_id"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "price_document_hash"
    t.string   "type"
    t.json     "config_document"
  end

  create_table "carrier_product_prices", force: :cascade do |t|
    t.integer "carrier_product_id"
    t.text    "price_document"
    t.string  "state",                     limit: 255
    t.binary  "marshalled_price_document"
  end

  add_index "carrier_product_prices", ["carrier_product_id"], name: "index_carrier_product_prices_on_carrier_product_id", using: :btree

  create_table "carrier_product_rules", force: :cascade do |t|
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "carrier_product_id", null: false
    t.string   "recipient_type"
    t.json     "recipient_location"
  end

  add_index "carrier_product_rules", ["carrier_product_id"], name: "index_carrier_product_rules_on_carrier_product_id", using: :btree

  create_table "carrier_products", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "carrier_id"
    t.integer  "carrier_product_id"
    t.string   "name",                         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                         limit: 255
    t.boolean  "is_disabled",                              default: false
    t.text     "credentials"
    t.boolean  "custom_volume_weight_enabled"
    t.integer  "volume_weight_factor"
    t.string   "track_trace_method",           limit: 255
    t.string   "state",                        limit: 255
    t.boolean  "custom_label",                             default: false
    t.boolean  "automatic_tracking",                       default: false
    t.string   "product_code"
    t.string   "product_type"
    t.text     "options"
    t.string   "transit_time"
    t.string   "custom_label_variant"
    t.boolean  "truck_driver_enabled",                     default: false
    t.string   "flag"
    t.string   "exchange_type"
  end

  add_index "carrier_products", ["carrier_product_id"], name: "index_carrier_products_on_carrier_product_id", using: :btree
  add_index "carrier_products", ["company_id"], name: "index_carrier_products_on_company_id", using: :btree

  create_table "carriers", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "carrier_id"
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.boolean  "disabled",               default: false
  end

  create_table "central_login_page_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "page_id",    null: false
    t.integer  "company_id", null: false
    t.integer  "sort_order"
  end

  create_table "central_login_pages", force: :cascade do |t|
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "title",           null: false
    t.string   "domain",          null: false
    t.integer  "primary_item_id"
  end

  add_index "central_login_pages", ["domain"], name: "index_central_login_pages_on_domain", unique: true, using: :btree

  create_table "companies", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "current_customer_id"
    t.string   "domain",               limit: 255
    t.string   "info_email",           limit: 255
    t.integer  "current_report_id"
    t.string   "initials"
    t.string   "primary_brand_color"
    t.integer  "current_truck_number",             default: 0
  end

  add_index "companies", ["initials"], name: "index_companies_on_initials", unique: true, using: :btree

  create_table "contacts", force: :cascade do |t|
    t.integer  "reference_id"
    t.string   "reference_type", limit: 255
    t.string   "company_name",   limit: 255
    t.string   "attention",      limit: 255
    t.string   "email",          limit: 255
    t.string   "phone_number",   limit: 255
    t.string   "address_line1",  limit: 255
    t.string   "address_line2",  limit: 255
    t.string   "zip_code",       limit: 255
    t.string   "city",           limit: 255
    t.string   "country_code",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",           limit: 255
    t.string   "state_code",     limit: 255
    t.string   "address_line3",  limit: 255
    t.string   "country_name",   limit: 255
    t.string   "cvr_number"
    t.text     "note"
    t.boolean  "residential"
  end

  add_index "contacts", ["reference_id", "reference_type"], name: "index_contacts_on_reference_id_and_reference_type", using: :btree
  add_index "contacts", ["type"], name: "index_contacts_on_type", using: :btree

  create_table "customer_billing_configurations", force: :cascade do |t|
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.datetime "disabled_at"
    t.string   "schedule_type",                         null: false
    t.json     "schedule_params"
    t.boolean  "with_detailed_pricing", default: false, null: false
    t.integer  "customer_recording_id",                 null: false
  end

  create_table "customer_carrier_products", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "carrier_product_id"
    t.boolean  "is_disabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enable_autobooking"
    t.boolean  "automatically_autobook"
    t.boolean  "test",                   default: false
    t.boolean  "allow_auto_pickup",      default: false
  end

  add_index "customer_carrier_products", ["carrier_product_id"], name: "ccp_carrier_product_id_index", using: :btree
  add_index "customer_carrier_products", ["customer_id", "carrier_product_id"], name: "ccp_customer_and_carrier_product_id_index", using: :btree
  add_index "customer_carrier_products", ["customer_id"], name: "ccp_customer_id_index", using: :btree

  create_table "customer_import_rows", force: :cascade do |t|
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "customer_import_id", null: false
    t.json     "field_data"
  end

  create_table "customer_imports", force: :cascade do |t|
    t.integer  "company_id",            null: false
    t.string   "status"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "created_by_id"
    t.json     "file_metadata"
    t.datetime "parsing_enqueued_at"
    t.datetime "parsing_completed_at"
    t.datetime "perform_enqueued_at"
    t.datetime "perform_completed_at"
    t.boolean  "send_invitation_email"
  end

  create_table "customer_recordings", force: :cascade do |t|
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "company_id",               null: false
    t.integer  "company_scoped_id"
    t.string   "type",                     null: false
    t.string   "customer_name"
    t.string   "normalized_customer_name"
    t.integer  "recordable_id",            null: false
    t.string   "recordable_type",          null: false
    t.datetime "disabled_at"
  end

  create_table "customers", force: :cascade do |t|
    t.string   "name",                           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id"
    t.integer  "current_shipment_id"
    t.integer  "current_pickup_id"
    t.integer  "current_end_of_day_manifest_id"
    t.integer  "customer_id"
    t.string   "external_accounting_number"
    t.boolean  "show_detailed_prices",                       default: false
    t.boolean  "allow_dangerous_goods",                      default: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",               default: 0, null: false
    t.integer  "attempts",               default: 0, null: false
    t.text     "handler",                            null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "deliveries", force: :cascade do |t|
    t.string   "unique_delivery_number"
    t.integer  "truck_delivery_number"
    t.integer  "truck_id"
    t.integer  "company_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "state"
  end

  add_index "deliveries", ["company_id"], name: "index_deliveries_on_company_id", using: :btree
  add_index "deliveries", ["truck_id"], name: "index_deliveries_on_truck_id", using: :btree

  create_table "deliveries_shipments", id: false, force: :cascade do |t|
    t.integer "shipment_id", null: false
    t.integer "delivery_id", null: false
  end

  create_table "deliveries_truck_drivers", force: :cascade do |t|
    t.integer "delivery_id"
    t.integer "truck_driver_id"
  end

  create_table "draft_reports", force: :cascade do |t|
    t.datetime "created_at",              null: false
    t.integer  "created_by_id"
    t.integer  "company_id",              null: false
    t.integer  "shipment_filter_id",      null: false
    t.integer  "report_configuration_id", null: false
    t.integer  "shipment_collection_id"
    t.datetime "collection_enqueued_at"
    t.datetime "collection_started_at"
    t.datetime "collection_finished_at"
    t.integer  "generated_report_id"
    t.datetime "report_enqueued_at"
    t.datetime "report_started_at"
    t.datetime "report_finished_at"
  end

  create_table "economic_accesses", force: :cascade do |t|
    t.datetime "created_at",                           null: false
    t.datetime "revoked_at"
    t.integer  "owner_id",                             null: false
    t.string   "owner_type",                           null: false
    t.string   "agreement_grant_token"
    t.boolean  "active",                default: true, null: false
    t.json     "self_response"
  end

  create_table "economic_invoice_exports", force: :cascade do |t|
    t.datetime "created_at",  null: false
    t.integer  "parent_id",   null: false
    t.string   "parent_type", null: false
    t.datetime "finished_at"
  end

  create_table "economic_invoice_lines", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "invoice_id",   null: false
    t.json     "payload"
    t.boolean  "includes_vat"
  end

  create_table "economic_invoice_shipments", force: :cascade do |t|
    t.integer "invoice_id",  null: false
    t.integer "shipment_id", null: false
  end

  create_table "economic_invoices", force: :cascade do |t|
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "parent_id",                                  null: false
    t.string   "parent_type",                                null: false
    t.integer  "seller_id",                                  null: false
    t.string   "seller_type",                                null: false
    t.integer  "buyer_id",                                   null: false
    t.string   "buyer_type",                                 null: false
    t.string   "currency"
    t.string   "external_accounting_number"
    t.boolean  "ready",                      default: false
    t.datetime "job_enqueued_at"
    t.datetime "http_request_sent_at"
    t.boolean  "http_request_succeeded"
    t.boolean  "http_request_failed"
  end

  create_table "economic_product_mappings", force: :cascade do |t|
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "owner_id",                null: false
    t.string   "owner_type",              null: false
    t.integer  "item_id",                 null: false
    t.string   "item_type",               null: false
    t.string   "product_number_incl_vat"
    t.string   "product_name_incl_vat"
    t.string   "product_number_excl_vat"
    t.string   "product_name_excl_vat"
  end

  create_table "economic_product_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "fetched_at"
    t.integer  "access_id",  null: false
  end

  create_table "economic_products", force: :cascade do |t|
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "access_id",                           null: false
    t.string   "number",                              null: false
    t.string   "name"
    t.json     "all_params"
    t.boolean  "no_longer_available", default: false, null: false
  end

  add_index "economic_products", ["access_id", "number"], name: "index_economic_products_on_access_id_and_number", unique: true, using: :btree

  create_table "economic_settings", force: :cascade do |t|
    t.integer  "company_id"
    t.string   "agreement_grant_token"
    t.string   "product_number_ex_vat"
    t.string   "product_number_inc_vat"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "product_name_inc_vat"
    t.string   "product_name_ex_vat"
  end

  add_index "economic_settings", ["company_id"], name: "index_economic_settings_on_company_id", using: :btree

  create_table "email_settings", force: :cascade do |t|
    t.integer  "user_id"
    t.boolean  "create",                 default: true
    t.boolean  "book",                   default: true
    t.boolean  "autobook_with_warnings", default: true
    t.boolean  "ship",                   default: true
    t.boolean  "delivered",              default: true
    t.boolean  "problem",                default: true
    t.boolean  "cancel",                 default: true
    t.boolean  "comment",                default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "pickup_create",          default: true
    t.boolean  "pickup_book",            default: true
    t.boolean  "pickup_pickup",          default: true
    t.boolean  "pickup_problem",         default: true
    t.boolean  "pickup_cancel",          default: true
    t.boolean  "pickup_comment",         default: true
    t.boolean  "rfq_create",             default: true
    t.boolean  "rfq_propose",            default: true
    t.boolean  "rfq_accept",             default: true
    t.boolean  "rfq_decline",            default: true
    t.boolean  "rfq_book",               default: true
    t.boolean  "rfq_cancel",             default: true
    t.boolean  "ferry_booking_booked",   default: false, null: false
    t.boolean  "ferry_booking_failed",   default: false, null: false
  end

  create_table "end_of_day_manifests", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "end_of_day_manifest_id"
  end

  create_table "end_of_day_manifests_shipments", force: :cascade do |t|
    t.integer "end_of_day_manifest_id"
    t.integer "shipment_id"
  end

  create_table "entity_relations", force: :cascade do |t|
    t.integer  "from_reference_id"
    t.string   "from_reference_type",        limit: 255
    t.integer  "to_reference_id"
    t.string   "to_reference_type",          limit: 255
    t.string   "relation_type",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "external_accounting_number"
  end

  create_table "eod_manifest_shipments", id: false, force: :cascade do |t|
    t.integer "manifest_id", null: false
    t.integer "shipment_id", null: false
  end

  create_table "eod_manifests", force: :cascade do |t|
    t.datetime "created_at",      null: false
    t.integer  "created_by_id"
    t.integer  "owner_id",        null: false
    t.string   "owner_type",      null: false
    t.integer  "owner_scoped_id", null: false
  end

  create_table "events", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "customer_id"
    t.string   "reference_type",     limit: 255
    t.integer  "reference_id"
    t.string   "event_type",         limit: 255
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "event_changes"
    t.string   "linked_object_type", limit: 255
    t.integer  "linked_object_id"
  end

  add_index "events", ["reference_type", "reference_id"], name: "index_events_on_reference_type_and_reference_id", using: :btree

  create_table "events_v2", force: :cascade do |t|
    t.datetime "created_at",             null: false
    t.string   "type",                   null: false
    t.string   "label",                  null: false
    t.integer  "eventable_id",           null: false
    t.string   "eventable_type",         null: false
    t.integer  "initiator_id"
    t.string   "initiator_type"
    t.string   "custom_initiator_label"
    t.text     "description"
  end

  add_index "events_v2", ["eventable_type", "eventable_id"], name: "index_events_v2_on_eventable_type_and_eventable_id", using: :btree

  create_table "feature_flags", force: :cascade do |t|
    t.datetime "created_at",    null: false
    t.datetime "revoked_at"
    t.integer  "resource_id",   null: false
    t.string   "resource_type", null: false
    t.string   "identifier",    null: false
  end

  add_index "feature_flags", ["resource_type", "resource_id", "identifier"], name: "index_feature_flags_on_resource_and_identifier", using: :btree

  create_table "ferry_booking_downloads", force: :cascade do |t|
    t.datetime "created_at",        null: false
    t.integer  "company_id",        null: false
    t.string   "unique_identifier", null: false
    t.text     "file_path"
    t.text     "document",          null: false
    t.datetime "parsed_at"
  end

  add_index "ferry_booking_downloads", ["company_id", "unique_identifier"], name: "index_fbd_on_company_id_and_unique_identifier", unique: true, using: :btree

  create_table "ferry_booking_requests", force: :cascade do |t|
    t.datetime "created_at",                   null: false
    t.integer  "ferry_booking_id",             null: false
    t.integer  "event_id"
    t.integer  "upload_id"
    t.string   "change",                       null: false
    t.string   "ref"
    t.integer  "failure_count",    default: 0, null: false
    t.datetime "completed_at"
  end

  create_table "ferry_booking_responses", force: :cascade do |t|
    t.datetime "created_at",       null: false
    t.integer  "ferry_booking_id", null: false
    t.integer  "event_id"
    t.integer  "download_id"
    t.json     "result"
  end

  create_table "ferry_booking_snapshots", force: :cascade do |t|
    t.integer "event_id",                      null: false
    t.boolean "initial_state", default: false, null: false
    t.json    "current_state"
    t.json    "diff"
  end

  create_table "ferry_booking_uploads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer  "company_id", null: false
    t.text     "file_path"
    t.text     "document",   null: false
  end

  create_table "ferry_bookings", force: :cascade do |t|
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "shipment_id",                                   null: false
    t.integer  "route_id",                                      null: false
    t.integer  "product_id",                                    null: false
    t.string   "truck_type"
    t.integer  "truck_length"
    t.string   "truck_registration_number"
    t.string   "trailer_registration_number"
    t.boolean  "with_driver"
    t.integer  "cargo_weight"
    t.boolean  "empty_cargo",                   default: false, null: false
    t.text     "description_of_goods"
    t.text     "additional_info"
    t.boolean  "transfer_in_progress",          default: false
    t.boolean  "waiting_for_response",          default: false
    t.string   "additional_info_from_response"
  end

  create_table "ferry_product_integrations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "company_id", null: false
    t.json     "settings"
  end

  create_table "ferry_products", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "disabled_at"
    t.integer  "route_id",           null: false
    t.string   "time_of_departure",  null: false
    t.integer  "carrier_product_id"
    t.integer  "integration_id"
    t.json     "pricing_schema"
  end

  create_table "ferry_routes", force: :cascade do |t|
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.datetime "disabled_at"
    t.integer  "company_id",     null: false
    t.string   "name",           null: false
    t.string   "port_code_from", null: false
    t.string   "port_code_to",   null: false
  end

  create_table "goods_lines", force: :cascade do |t|
    t.integer "container_id",                     null: false
    t.integer "quantity",                         null: false
    t.string  "goods_identifier",                 null: false
    t.integer "length"
    t.integer "width"
    t.integer "height"
    t.decimal "weight"
    t.decimal "volume_weight"
    t.boolean "non_stackable",    default: false, null: false
  end

  create_table "invoice_validation_row_records", force: :cascade do |t|
    t.integer  "invoice_validation_id",                               null: false
    t.string   "unique_shipment_id"
    t.string   "expected_price_currency"
    t.decimal  "expected_price_amount",     precision: 20, scale: 12
    t.string   "actual_cost_currency"
    t.decimal  "actual_cost_amount",        precision: 20, scale: 12
    t.string   "difference_price_currency"
    t.decimal  "difference_price_amount",   precision: 20, scale: 12
    t.json     "field_data"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
  end

  add_index "invoice_validation_row_records", ["invoice_validation_id"], name: "index_invoice_validation_row_records_on_invoice_validation_id", using: :btree
  add_index "invoice_validation_row_records", ["unique_shipment_id", "invoice_validation_id"], name: "index_error_rows_on_unique_shipment_and_invoice_validation_ids", unique: true, using: :btree

  create_table "invoice_validations", force: :cascade do |t|
    t.string   "name"
    t.string   "key"
    t.string   "shipment_id_column"
    t.string   "cost_column"
    t.string   "status"
    t.json     "header_row"
    t.integer  "processed_shipments_count"
    t.integer  "company_id",                 null: false
    t.string   "errors_report_download_url"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "invoice_validations", ["company_id"], name: "index_invoice_validations_on_company_id", using: :btree

  create_table "invoicing_methods", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string  "type"
  end

  add_index "invoicing_methods", ["company_id"], name: "index_invoicing_methods_on_company_id", unique: true, using: :btree

  create_table "notes", force: :cascade do |t|
    t.integer  "creator_id"
    t.string   "creator_type",       limit: 255
    t.integer  "linked_object_id"
    t.string   "linked_object_type", limit: 255
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notes", ["linked_object_id", "linked_object_type", "creator_id", "creator_type"], name: "notes_index", unique: true, using: :btree

  create_table "number_series", force: :cascade do |t|
    t.datetime "created_at",              null: false
    t.datetime "disabled_at"
    t.string   "type"
    t.integer  "next_value",  default: 0, null: false
    t.integer  "max_value",               null: false
    t.json     "metadata"
  end

  create_table "package_recordings", force: :cascade do |t|
    t.datetime "created_at",          null: false
    t.integer  "package_id",          null: false
    t.decimal  "weight_value"
    t.decimal  "volume_weight_value"
    t.string   "weight_unit"
    t.json     "fee_data"
    t.json     "dimensions"
  end

  create_table "package_updates", force: :cascade do |t|
    t.datetime "created_at",           null: false
    t.integer  "feedback_file_id"
    t.integer  "package_id"
    t.integer  "package_recording_id"
    t.json     "metadata"
    t.datetime "applied_at"
    t.datetime "failed_at"
    t.string   "failure_reason"
    t.boolean  "failure_handled"
  end

  create_table "packages", force: :cascade do |t|
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "shipment_id",         null: false
    t.integer  "active_recording_id"
    t.string   "unique_identifier"
    t.json     "metadata"
    t.string   "type"
    t.integer  "package_index"
  end

  create_table "permissions", force: :cascade do |t|
    t.integer  "company_id"
    t.string   "permission"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pickups", force: :cascade do |t|
    t.integer  "company_id"
    t.date     "pickup_date"
    t.string   "from_time",             limit: 255
    t.string   "to_time",               limit: 255
    t.text     "description"
    t.string   "state",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.integer  "pickup_id"
    t.string   "unique_pickup_id",      limit: 255
    t.boolean  "auto",                              default: false
    t.string   "bll"
    t.string   "carrier_identifier"
    t.json     "response_from_carrier"
  end

  create_table "price_document_uploads", force: :cascade do |t|
    t.datetime "created_at",         null: false
    t.integer  "created_by_id"
    t.integer  "company_id",         null: false
    t.integer  "carrier_product_id", null: false
    t.string   "original_filename"
    t.string   "s3_object_key"
    t.boolean  "active",             null: false
  end

  create_table "rate_sheets", force: :cascade do |t|
    t.datetime "created_at",                    null: false
    t.integer  "created_by_id"
    t.integer  "company_id",                    null: false
    t.integer  "customer_recording_id",         null: false
    t.integer  "carrier_product_id",            null: false
    t.integer  "base_price_document_upload_id", null: false
    t.json     "margins"
    t.json     "rate_snapshot"
  end

  create_table "report_configurations", force: :cascade do |t|
    t.datetime "created_at",            null: false
    t.integer  "company_id",            null: false
    t.boolean  "with_detailed_pricing", null: false
    t.boolean  "ferry_booking_data"
    t.boolean  "truck_driver_data"
  end

  create_table "report_shipment_filters", force: :cascade do |t|
    t.datetime "created_at",            null: false
    t.integer  "company_id",            null: false
    t.integer  "customer_recording_id"
    t.integer  "carrier_id"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "report_inclusion"
    t.string   "pricing_status"
    t.string   "shipment_state"
  end

  create_table "reports", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "report_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.string   "download_url"
    t.string   "economic_invoices_state"
    t.boolean  "with_detailed_pricing",   default: false
    t.integer  "customer_recording_id"
    t.boolean  "ferry_booking_data",      default: false
    t.boolean  "truck_driver_data",       default: false
  end

  create_table "reports_shipments", force: :cascade do |t|
    t.integer "report_id"
    t.integer "shipment_id"
  end

  create_table "rule_intervals", force: :cascade do |t|
    t.integer "rule_id",                        null: false
    t.boolean "enabled",        default: false, null: false
    t.string  "type"
    t.string  "interval_type"
    t.string  "from"
    t.boolean "from_inclusive"
    t.string  "to"
    t.boolean "to_inclusive"
  end

  add_index "rule_intervals", ["rule_id"], name: "index_rule_intervals_on_rule_id", using: :btree

  create_table "sales_prices", force: :cascade do |t|
    t.float    "margin_percentage"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "reference_id"
    t.string   "reference_type",    limit: 255
    t.boolean  "use_margin_config"
    t.integer  "margin_config_id"
  end

  add_index "sales_prices", ["reference_id", "reference_type"], name: "index_sales_prices_on_reference_id_and_reference_type", using: :btree

  create_table "scoped_counters", force: :cascade do |t|
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "owner_id",               null: false
    t.string   "owner_type",             null: false
    t.string   "type"
    t.string   "identifier"
    t.integer  "value",      default: 0, null: false
  end

  create_table "shipment_additional_surcharges", force: :cascade do |t|
    t.integer "shipment_id",     null: false
    t.string  "surcharge_type"
    t.json    "surcharge_props"
  end

  create_table "shipment_collection_items", force: :cascade do |t|
    t.integer "shipment_collection_id",                null: false
    t.integer "shipment_id",                           null: false
    t.boolean "selected",               default: true, null: false
  end

  create_table "shipment_collections", force: :cascade do |t|
  end

  create_table "shipment_export_runs", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.integer  "owner_id",     null: false
    t.string   "owner_type",   null: false
    t.text     "xml_response"
  end

  create_table "shipment_export_settings", force: :cascade do |t|
    t.string   "owner_type",                             null: false
    t.integer  "owner_id",                               null: false
    t.boolean  "booked",                 default: false
    t.boolean  "in_transit",             default: false
    t.boolean  "delivered",              default: false
    t.boolean  "problem",                default: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "trigger_when_created",   default: false, null: false
    t.boolean  "trigger_when_cancelled", default: false, null: false
  end

  add_index "shipment_export_settings", ["owner_id", "owner_type"], name: "index_shipment_export_settings_on_owner_id_and_owner_type", unique: true, using: :btree

  create_table "shipment_exports", force: :cascade do |t|
    t.string   "owner_type",                  null: false
    t.integer  "owner_id",                    null: false
    t.integer  "shipment_id",                 null: false
    t.boolean  "exported",    default: false
    t.boolean  "updated",     default: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "shipment_exports", ["shipment_id", "owner_id", "owner_type"], name: "shipment_exports_unique_index", unique: true, using: :btree

  create_table "shipment_goods", force: :cascade do |t|
    t.datetime "created_at",     null: false
    t.integer  "shipment_id",    null: false
    t.string   "volume_type",    null: false
    t.string   "dimension_unit", null: false
    t.string   "weight_unit",    null: false
  end

  create_table "shipment_requests", force: :cascade do |t|
    t.integer  "shipment_id"
    t.string   "state"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "shipment_requests", ["shipment_id"], name: "index_shipment_requests_on_shipment_id", using: :btree

  create_table "shipment_truck_drivers", force: :cascade do |t|
    t.datetime "created_at",      null: false
    t.integer  "shipment_id",     null: false
    t.integer  "truck_driver_id", null: false
  end

  create_table "shipments", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "carrier_product_id"
    t.date     "shipping_date"
    t.boolean  "dutiable"
    t.decimal  "customs_amount",                                precision: 8, scale: 2
    t.string   "customs_currency",                  limit: 255
    t.string   "customs_code",                      limit: 255
    t.integer  "number_of_packages"
    t.text     "package_dimensions"
    t.text     "description"
    t.string   "state",                             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.string   "awb",                               limit: 255
    t.integer  "shipment_id"
    t.text     "shipment_errors"
    t.string   "external_awb_asset",                limit: 255
    t.string   "unique_shipment_id",                limit: 255
    t.text     "shipment_warnings"
    t.string   "shipment_type",                     limit: 255
    t.string   "reference",                         limit: 255
    t.string   "parcelshop_id"
    t.boolean  "return_label",                                                          default: false
    t.string   "remarks"
    t.string   "delivery_instructions"
    t.integer  "pickup_id"
    t.boolean  "dangerous_goods",                                                       default: false
    t.string   "dangerous_goods_description"
    t.string   "un_number"
    t.string   "un_packing_group"
    t.string   "packing_instruction"
    t.string   "dangerous_goods_class"
    t.boolean  "ferry_booking_shipment",                                                default: false
    t.string   "dangerous_goods_predefined_option"
    t.boolean  "tracking_packages",                                                     default: false, null: false
    t.date     "estimated_arrival_date"
    t.integer  "number_of_pallets"
    t.integer  "goods_id"
  end

  add_index "shipments", ["carrier_product_id"], name: "index_shipments_on_carrier_product_id", using: :btree
  add_index "shipments", ["company_id"], name: "index_shipments_on_company_id", using: :btree
  add_index "shipments", ["customer_id"], name: "index_shipments_on_customer_id", using: :btree

  create_table "surcharges", force: :cascade do |t|
    t.string "type"
    t.json   "charge_data"
    t.string "description"
  end

  create_table "surcharges_on_carriers", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.datetime "disabled_at"
    t.integer  "surcharge_id"
    t.integer  "carrier_id",   null: false
  end

  create_table "surcharges_on_products", force: :cascade do |t|
    t.datetime "created_at",         null: false
    t.datetime "disabled_at"
    t.integer  "parent_id",          null: false
    t.integer  "surcharge_id"
    t.integer  "carrier_product_id", null: false
  end

  create_table "surcharges_with_expiration", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.integer  "owner_id",     null: false
    t.string   "owner_type",   null: false
    t.integer  "surcharge_id"
    t.datetime "valid_from"
    t.datetime "expires_on"
  end

  create_table "token_sessions", force: :cascade do |t|
    t.datetime "created_at",        null: false
    t.integer  "company_id",        null: false
    t.integer  "sessionable_id",    null: false
    t.string   "sessionable_type",  null: false
    t.string   "type"
    t.string   "token_value",       null: false
    t.json     "metadata"
    t.datetime "last_used_at"
    t.datetime "expired_at"
    t.string   "expiration_reason"
  end

  add_index "token_sessions", ["token_value"], name: "index_token_sessions_on_token_value", unique: true, using: :btree

  create_table "tokens", force: :cascade do |t|
    t.string   "type"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "value"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.boolean  "force_ssl",  default: true, null: false
  end

  create_table "trackings", force: :cascade do |t|
    t.string   "type",                   limit: 255
    t.string   "status",                 limit: 255
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "event_date"
    t.date     "expected_delivery_date"
    t.string   "signatory",              limit: 255
    t.string   "event_country",          limit: 255
    t.string   "event_city",             limit: 255
    t.string   "event_zip_code",         limit: 255
    t.string   "depot_name",             limit: 255
    t.datetime "event_time"
    t.datetime "expected_delivery_time"
  end

  create_table "truck_drivers", force: :cascade do |t|
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.datetime "disabled_at"
    t.integer  "company_id",  null: false
    t.string   "name"
    t.integer  "user_id"
  end

  create_table "trucks", force: :cascade do |t|
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "name"
    t.datetime "disabled_at"
    t.integer  "company_id"
    t.integer  "company_truck_number"
    t.integer  "current_delivery_number", default: 0
    t.integer  "delivery_id"
    t.integer  "active_delivery_id"
    t.integer  "default_driver_id"
  end

  add_index "trucks", ["company_id"], name: "index_trucks_on_company_id", using: :btree
  add_index "trucks", ["delivery_id"], name: "index_trucks_on_delivery_id", using: :btree

  create_table "user_customer_accesses", force: :cascade do |t|
    t.datetime "created_at",  null: false
    t.datetime "revoked_at"
    t.integer  "user_id",     null: false
    t.integer  "company_id",  null: false
    t.integer  "customer_id", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.integer  "failed_attempts",                    default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id"
    t.integer  "customer_id"
    t.boolean  "is_admin",                           default: false
    t.boolean  "is_customer",                        default: false
    t.boolean  "is_executive",                       default: false
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  add_foreign_key "deliveries", "companies"
  add_foreign_key "deliveries", "trucks"
  add_foreign_key "invoice_validation_row_records", "invoice_validations"
  add_foreign_key "invoice_validations", "companies"
  add_foreign_key "shipment_requests", "shipments"
  add_foreign_key "trucks", "companies"
  add_foreign_key "trucks", "deliveries"
  add_foreign_key "trucks", "deliveries", column: "active_delivery_id"
end
