class API::V1::Companies::ShipmentExportsController < API::V1::Companies::CompaniesController
  around_action :wrap_in_transaction, only: :create

  def index
    since = nil

    if params[:since].present?
      begin
        since = Time.parse(params[:since])
      rescue ArgumentError
        respond_to do |format|
          format.xml { render :invalid_since_timestamp, status: :bad_request }
        end

        return
      end
    end

    runs = ShipmentExportRun.where(owner: current_company).order(:id)
    runs = runs.where("created_at > ?", since) if since.present?
    runs = runs.limit(50)

    xml_builder = Nokogiri::XML::Builder.new do |xml|
      xml.ShipmentLists do
        runs.each do |run|
          doc = Nokogiri::XML(run.xml_response)
          root = doc.root
          root["timestamp"] = run.created_at

          xml << root.to_s
        end
      end
    end

    respond_to do |format|
      format.xml { render xml: xml_builder.to_xml }
    end
  end

  def create
    interactor_params = { company_id: current_company.id }
    interactor = ::Companies::ShipmentExports::Export.new(interactor_params)

    result = interactor.run

    @view_model = API::V1::Companies::ShipmentExports::ListView.new(company: current_company, new: result.new, updated: result.updated)

    run = ShipmentExportRun.new(owner: current_company)

    respond_to do |format|
      format.xml do
        xml_response = render_to_string(:show, formats: [:xml])
        run.xml_response = xml_response

        render xml: xml_response, status: :ok
      end
    end

    run.save!
  end

  private

  def wrap_in_transaction
    ActiveRecord::Base.transaction do
      yield
    end
  end
end
