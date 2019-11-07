module CFExec
  class CompaniesController < ExecController
    def index
      @companies = Company.all.order(id: :asc).page(params[:page]).per(100)

      respond_to do |format|
        format.html
      end
    end

    def show
      @company = Company.find(params[:id])
      @view_model = ShowViewModel.new(@company)
      @customer_view_model = ShowViewModelForCustomers.new(@company)
    end

    def new
      @company = CompanyForm.new
    end

    def create
      @company = CompanyForm.new(params.require(:company).permit(:name, :initials, :info_email, :domain, :user_email))

      if @company.save
        redirect_to exec_company_path(@company.record_id)
      else
        render :new
      end
    end

    def edit
      @company = CompanyForm.edit_by_record_id(params[:id])
    end

    def update
      @company = CompanyForm.edit_by_record_id(params[:id])
      @company.assign_attributes(params.require(:company).permit(:name, :initials, :info_email, :domain, :user_email))

      if @company.save
        redirect_to exec_company_path(@company.record_id)
      else
        render :new
      end
    end

    private

    def active_nav
      case params[:action]
      when "index"
        [:companies, :index]
      when "show"
        [:companies, :show]
      when "new", "create"
        [:companies, :new]
      when "edit", "update"
        [:companies, :edit]
      end
    end

    class ShowViewModel
      attr_reader :company

      def initialize(company)
        @company = company
      end

      def enabled_carriers
        Carrier
          .where(company: company)
          .where(carrier_id: cf_carriers.select(:id))
          .where.not(disabled: true)
      end

      def available_carriers
        cf_carriers
          .where.not(id: enabled_carriers.select(:carrier_id))
          .where.not(disabled: true)
      end

      private

      def cf_carriers
        Carrier.where(company_id: CargofluxCompany.find_id!)
      end
    end

    class ShowViewModelForCustomers
      attr_reader :company

      def initialize(company)
        @company = company
      end

      def ordered_buying_customers
        customers_buying_from_company.order(:name)
      end

      def ordered_available_buying_customers
        available_carrier_product_customers.order(:name)
      end

      private

      def customers_buying_from_company
        Company.where(id: carrier_product_customer_entity_relations.select(:to_reference_id))
      end

      def available_carrier_product_customers
        Company
          .where.not(id: carrier_product_customer_entity_relations.select(:to_reference_id))
          .where.not(id: company.id)
          .where.not(id: CargofluxCompany.find_id!)
      end

      def carrier_product_customer_entity_relations
        EntityRelation
          .where(from_reference: company)
          .where(to_reference_type: "Company")
          .where(relation_type: EntityRelation::RelationTypes::CARRIER_PRODUCT_CUSTOMER)
      end
    end
  end
end
