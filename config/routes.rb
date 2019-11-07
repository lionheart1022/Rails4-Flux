Cargoflux::Application.routes.draw do
  root "home#index"

  post "login-page/:id/redirect", to: "home#login_page_redirect", as: "login_page_redirect"
  get "login-page/:id/select", to: "home#login_page_select", as: "login_page_select"

  get "admin", to: "admin_home#index", as: "admin_root"

  get "select-account", to: "account_selector#index", as: "account_selector"

  scope as: "customer_user", path: "cu-users" do
    scope controller: "customer_user_confirmations" do
      get "confirmation", action: "show"
      put "confirmation", action: "update"
    end
  end

  scope as: "company_user", path: "co-users" do
    scope controller: "company_user_confirmations" do
      get "confirmation", action: "show"
      put "confirmation", action: "update"
    end
  end

  get "password_reset", to: "password_resets#new", as: "new_password_reset"
  post "password_reset", to: "password_resets#create", as: "password_reset"
  get "password_reset/sent", to: "password_resets#sent", as: "sent_password_reset"
  get "password_reset/edit", to: "password_resets#edit", as: nil
  put "password_reset", to: "password_resets#update", as: nil

  # This route takes precedence over the one created by Devise
  get "/users/password/edit", to: "password_resets#edit", as: nil

  namespace :exec, module: "cf_exec" do
    get "/", to: "companies#index"

    resources :shipments, only: [:index]

    resources :users, only: [:index, :show] do
      resources :features, controller: "user_features", only: [:create, :destroy]
      resource :notification, controller: "user_notifications", only: [:destroy]
      resources :notification_settings, controller: "user_notification_settings", only: [:create, :destroy]
    end

    resources :companies, except: :destroy do
      resources :addons, controller: "company_addons", only: [:create, :destroy]
      resources :features, controller: "company_features", only: [:create, :destroy]
      resources :carriers, controller: "company_carriers", only: [:create]
      resources :customers, controller: "company_customers", only: [:create]
      resources :gls_feedback_configurations, only: [:create]
      resource :color_theme, controller: "company_color_themes", only: [:show, :update, :destroy] do
        post :try, on: :member
      end
    end

    resources :login_pages, only: [:index]

    resources :company_tokens, only: [:index, :show] do
      member do
        post "unsafe_access", action: "allow_unsafe_access"
        post "safe_access", action: "force_safe_access"
      end
    end

    resources :company_carriers, controller: "company_carriers", only: [:show, :destroy] do
      resources :products, controller: "company_carrier_products", only: [:create, :destroy]
    end

    resources :carriers, only: [:index, :show] do
      member do
        get "copy", action: "new_copy"
        post "copy", action: "create_copy"
      end
    end

    resource :invoicing_report, only: [:show]
    resources :invoicing_methods, only: [:index, :create, :destroy]
  end

  scope as: "api", path: "api" do
    namespace :app, module: "api_for_app" do
      get "/", to: "sessions#show"

      resource :session, only: [:show, :create, :destroy]
      resource :company, only: [:show]

      # This should always be in the bottom
      match "*path", to: "router_errors#not_found", via: :all
    end
  end

  namespace :api_v1_for_customers, path: "api/v1/customers" do
    post "shipments", to: "shipments#create", defaults: { format: "json" }
    put "shipments", to: "shipments#update", defaults: { format: "json" }
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      namespace :customers do
        resources :shipment_prices, path: "shipments/prices", only: [:create]

        resources :shipments, only: [:show]
        post "address/import", to: "address_imports#create"
      end

      namespace :companies do
        resources :shipments, only: [:index, :show]
        resources :shipment_exports, only: [:index, :create]

        post "shipment_updates", to: "shipment_bulk_updates#create"
      end
    end
  end

  devise_for(
    :users,
    controllers: {
      sessions: "sessions",
      passwords: "passwords",
      confirmations: "confirmations",
      unlocks: "unlocks",
    }
  )

  # Customer actions
  scope module: "customers", as: "customers", path: "customers(/:current_customer_identifier)" do
    resource :user_profile, only: [:show, :update]

    resources :autocomplete_carriers, only: [:index], defaults: { format: "json" }

    resource :address, only: [:show, :edit, :update]
    resource :notification, only: [:show, :update]
    resource :access_token, only: [:show, :update]

    # This route ensures backwards compatibility for the deprecated `resource :tokens, only: [:edit, :update]`
    get "/tokens/edit", to: "access_tokens#show", as: nil

    resources :shipment_requests do
      collection do
        post 'get_carrier_products_and_prices_for_shipment'
      end
    end

    resources :rate_sheets, only: [:index] do
      get :print, on: :member
    end

    get "/terms_and_conditions", to: "company#terms_and_conditions"

    resources :pickups, only: [:index, :new, :create, :show] do
      collection do
        get 'archived'
      end
    end

    resources :shipments, only: [:index, :new, :create] do
      collection do
        get  'archived'
        post 'get_carrier_products_and_prices_for_shipment'
        get 'search'
      end
      member do
        post 's3_invoice_callback'
        post 's3_other_callback', to: 'other_assets#callback'
        put  'cancel_shipment'
      end
      resource :custom_label, only: :show
      resource :proforma_invoice, only: :show
      resources :attachments, only: [:destroy]
      resource :note, controller: "shipment_notes", only: [:update]
    end

    resources :shipment_prebook_checks, only: [:create], controller: "/cf_app/shipment_prebook_checks", defaults: { format: "json" }, app_scope: "customers"

    resources :shipments, controller: "shipments",      only: [:show, :edit, :update], constraints: ShipmentRouteConstraint.match_regular_shipments
    resources :shipments, controller: "ferry_bookings", only: [:show, :edit, :update], constraints: ShipmentRouteConstraint.match_ferry_booking_shipments

    resources :ferry_bookings, only: [:new, :create] do
      patch "cancel", on: :member
    end

    resources :end_of_day_manifests, only: [:index, :new, :show, :create] do
      get :print, on: :member
    end

    resources :autocomplete_contacts, only: [:index], controller: "/cf_app/autocomplete_contacts", defaults: { format: "json" }, app_scope: "customers"
    resources :contacts, controller: "/cf_app/contacts", app_scope: "customers"
    resources :contact_imports, only: [:index, :new, :create], controller: "/cf_app/contact_imports", app_scope: "customers"

    get "/address_book", to: "/cf_app/contacts#index", app_scope: "customers"
  end

  # Company actions
  namespace :companies do
    get "dashboard", to: "dashboard#index"
    get "dashboard_data", to: "dashboard_data#index", defaults: { format: "json" }

    resource :user_profile, only: [:show, :update]

    resources :autocomplete_carriers, only: [:index], defaults: { format: "json" }
    resources :autocomplete_customers, only: [:index], defaults: { format: "json" }
    resources :autocomplete_direct_customers, only: [:index], defaults: { format: "json" }

    resources :autocomplete_contacts, only: [:index], controller: "/cf_app/autocomplete_contacts", defaults: { format: "json" }, app_scope: "companies"
    resources :contacts, controller: "/cf_app/contacts", app_scope: "companies"
    resources :contact_imports, only: [:index, :new, :create], controller: "/cf_app/contact_imports", app_scope: "companies"

    get "/address_book", to: "/cf_app/contacts#index", app_scope: "companies"

    resources :users
    resources :all_customer_users, path: "customer_users", only: [:index]
    resource :notification, only: [:show, :update]
    resource :shipment_export_configuration, path: "export_configuration", only: [:show, :update]
    resources :access_tokens, only: [:index, :show, :create]

    get "customers", to: "customer_recordings#index"
    get "carrier_product_customers", to: "customer_recordings#index"

    scope as: "customer_scoped", path: "customers/:selected_customer_identifier" do
      resources :shipment_request_prices, path: "rfq-prices", only: [:create]

      resources :carrier_pickups, only: [] do
        get "select_carrier", on: :collection
      end
      resources :ups_pickups, only: [:new, :create] do
        post "confirm", on: :collection
      end
    end

    resources :carrier_pickups, only: [] do
      get "select_customer", on: :collection
    end

    resources :shipment_requests, only: [:index, :new, :create, :show, :update] do
      member do
        put "book"
      end
    end

    resources :customers, only: [:new, :create] do
      get "settings", on: :member

      resource :dgr, controller: "customer_dangerous_goods", only: [:create, :destroy]
      resource :detailed_pricing, controller: "customer_detailed_pricing", only: [:create, :destroy]
      resource :billing_configuration, path: "billing", controller: "customer_billing_configurations", only: [:show, :update]
      resources :users, controller: "customer_users", only: [:index, :new, :create, :destroy]
      resources :carriers, controller: "customer_carriers", only: [:index, :show] do
        resource :credential_configuration, controller: "customer_carrier_credential_configurations", only: [:show, :update], path: "credentials"
      end
      resource :address, controller: "customer_addresses", only: [:show, :edit, :update]

      resources :carrier_products, controller: "customer_carrier_products", only: [:update] do
        resource :margin_configuration, controller: "customer_carrier_product_margin_configurations", only: [:show, :update]
      end

      resources :rate_sheets, controller: "customer_rate_sheets", only: [:create, :show] do
        get :print, on: :member
      end
    end

    get "customers/:customer_id", to: "customer_carriers#index", as: :customer

    resources :autocomplete_customer_recordings, path: "customer_recordings/autocomplete", only: [:index]
    resources :customer_recordings, only: [:index]

    resources :customer_imports, only: [:new, :show] do
      post "bg", action: "parse_in_background", on: :collection
      post "bg", action: "perform_in_background", on: :member
      get "progress", on: :member
    end

    resources :carrier_product_customers, only: [] do
      member do
        put 'update_economic'
      end

      resources :carrier_product_customer_carriers, path: '', only: [:index, :new, :create] do
        collection do
          put 'batch_disable'
        end

        resources :carrier_product_customer_carrier_products, path: 'products', only: [:index, :new, :create] do
          collection do
            patch "set_carrier_products_and_sales_prices"
          end
        end
      end

      resource :billing_configuration, path: "billing", controller: "carrier_product_customer_billing_configurations", only: [:show, :update]
    end

    resources :draft_reports, only: [:new, :create, :show] do
      member do
        get :wait
        get :in_progress
        post :complete
        post :toggle_shipment
        post :toggle_all_shipments
      end
    end

    resources :reports, only: [:index, :show] do
      member do
        post "export_economic"
      end

      resources :excel_exports, controller: "report_excel_exports", only: [:create]
      resource :excel_export_status, controller: "report_excel_export_statuses", only: [:show]

      resource :economic_invoice_export, path: "e_conomic/invoice_export", only: [:create] do
        get :in_progress
      end

      resources :economic_invoices, path: "e_conomic/invoices", only: [:index, :show] do
        put :bulk_update, on: :collection
        get :in_progress, on: :collection
      end
    end

    resources :pickups, only: [:index, :show] do
      collection do
        get 'archived'
      end

      resources :state_changes, controller: "pickup_state_changes", only: :create
    end

    namespace :shipment_updates do
      resources :gls_feedback_files, path: "gls", only: [:new, :create]
    end

    resources :shipment_updates, only: [:index, :show, :new] do
      resources :package_updates, only: [] do
        post "apply", on: :member
      end
    end

    resources :carrier_feedback_configurations, only: [:index]

    resources :unbilled_shipments, only: [:index]

    resources :shipments, only: [:index, :new, :create] do
      collection do
        get 'archived'
        get 'search', to: 'shipment_search#index'
        post 'get_carrier_products_and_prices_for_shipment'
      end
      member do
        post 's3_other_callback', to: 'other_assets#callback'
        post 's3_awb_callback'
        post 's3_invoice_callback'
        post 's3_consignment_note_callback'
        post 'autobook'
        post 'retry_awb_document'
        post 'retry_consignment_note'
        post 'update_owner_price'
        post 'update_customer_price'
        delete 'remove_attachment'
        put  'cancel_shipment'
      end
      resources :autobook_requests, controller: "shipment_autobook_requests", only: [:show]
      resource :custom_label, only: :show
      resource :proforma_invoice, only: :show
      resources :attachments, only: [:destroy]
      resource :note, controller: "shipment_notes", only: [:update]
      resources :prices, only: [:create, :destroy] do
        member do
          post 'set_sales_price'
        end
      end
    end

    resource :truck_fleet, only: [:show]

    resources :deliveries, only: [:show, :destroy]

    resources :shipment_prebook_checks, only: [:create], controller: "/cf_app/shipment_prebook_checks", defaults: { format: "json" }, app_scope: "companies"

    resources :shipments, controller: "shipments", only: [:show, :edit, :update], constraints: ShipmentRouteConstraint.match_regular_shipments
    resources :shipments, only: [], constraints: ShipmentRouteConstraint.match_regular_shipments(:shipment_id) do
      resources :state_changes, controller: "shipment_state_changes", only: :create
      resource :truck_driver, controller: "shipment_truck_drivers", only: [:update]
      resource :delivery, controller: "shipment_deliveries", only: [:update]
    end

    resources :shipments, controller: "ferry_bookings", only: [:show, :edit, :update], constraints: ShipmentRouteConstraint.match_ferry_booking_shipments
    resources :shipments, only: [], constraints: ShipmentRouteConstraint.match_ferry_booking_shipments(:shipment_id) do
      resources :state_changes, controller: "ferry_booking_state_changes", only: :create
    end

    resources :shipment_state_changes, only: [] do
      patch "bulk_update", on: :collection
    end

    resources :ferry_bookings, only: [:new, :create] do
      patch "cancel", on: :member
    end
    resources :ferry_routes, only: [:index] do
      resource :configuration, controller: "ferry_route_configurations", only: [:show, :update]
    end

    resources :invoice_validations do
      member do
        get 'export_excel_file'
        get 'in_progress'
      end
    end

    resources :autobooking_requests, only: [:index, :show]

    resources :carriers, except: [:destroy] do
      put "bulk_update", on: :member

      resources :products, only: [:new, :create], controller: "carrier_products"

      resources :surcharges, controller: "carrier_surcharges", only: [:index, :new, :create] do
        patch :bulk_update, on: :collection
        get :v2, action: "index_v2", on: :collection
        patch :bulk_update_v2, on: :collection
      end
    end

    resources :carrier_products, only: [:edit, :update], controller: "carrier_products" do
      patch "disable", on: :member

      resource :credential, controller: "carrier_product_credentials", only: [:show, :edit, :update]

      resources :rules, controller: "carrier_product_rules", only: [:index, :new, :create, :edit, :update, :destroy]

      resources :surcharges, controller: "carrier_product_surcharges", only: [:index, :destroy] do
        patch :bulk_update, on: :collection
        get :v2, action: "index_v2", on: :collection
        patch :bulk_update_v2, on: :collection
      end
    end

    namespace :price_documents do
      get "/", to: "carriers#index"

      resources :carriers, only: [:index, :show]
      resources :carrier_products, only: [:show, :update, :destroy] do
        post :download, action: "redirect_to_download_url", on: :member
      end
    end

    resources :surcharges, only: [:index]

    resources :end_of_day_manifests, only: [:index, :new, :show, :create] do
      get :print, on: :member
    end

    resource :economic, only: [:edit, :update] do
      member do
        get "callback"
      end
    end

    scope path: "e_conomic", as: "v2_economic" do
      get "/", to: "economic_carriers#index"

      resource :access, controller: "economic_accesses", only: [:create] do
        get "callback"
      end

      resources :carriers, controller: "economic_carriers", only: [:index] do
        get "/", to: "economic_carrier_products#index"
      end

      resources :carrier_products, controller: "economic_carrier_products", only: [:edit, :update] do
        get "cancel_edit", on: :member
      end

      resources :product_requests, controller: "economic_product_requests", only: [:create] do
        get "fetch_status", on: :collection
      end

      resources :products, controller: "economic_products", only: [] do
        get "select_element", on: :collection
      end
    end

    resources :trucks, except: [:edit]

    resources :truck_drivers, except: [:edit] do
      resource :user, controller: "truck_driver_users", only: [:new, :create, :destroy]
      resources :sessions, controller: "truck_driver_sessions", only: [:index]
    end

    # Route defined for backwards compability
    get "/settings", to: "settings#show"

    resource :setting, only: [:show]

    resource :company_logo, only: [:destroy] do
      post :callback
    end

    resource :company_address, only: [:update]

    get "/whats_new", to: "announcements#index", as: "whats_new"
    get "/whats-new", to: "announcements#index", as: nil
    get "/whatsnew", to: "announcements#index", as: nil

    get "/terms_and_conditions",                       to: "company#terms_and_conditions"
    post "/terms_and_conditions/s3_company_callback",  to: "company#s3_company_callback"
    delete "/terms_and_conditions/:id",                to: "company#delete_terms_and_condition", as: "terms_and_condition"
  end
end
