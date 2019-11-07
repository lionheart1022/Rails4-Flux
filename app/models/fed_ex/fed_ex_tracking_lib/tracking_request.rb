class FedExTrackingLib
  class TrackingRequest
    attr_reader :awb, :credentials

    delegate :developer_key, :developer_password, :account_number, :meter_number,
      to: :credentials

    def initialize(awb, credentials)
      @awb = awb
      @credentials = credentials
    end

    def request
      load_xml(filename: 'fed_ex_tracking_request_template.xml.erb', binding: binding)
    end

    private

    def load_xml(filename: nil, binding: nil)
      path = File.join(Rails.root, 'app', 'models', 'templates', filename)
      xml_template = ERB.new(File.read(path))
      xml_template.result(binding)
    end
  end
end
