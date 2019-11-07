class GeodisBookingResponse
  class << self
    def parse(response_body)
      doc = Nokogiri::XML(response_body, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET)

      # When Geodis has transitioned to the new https://portal.ff.geodis.com endpoint officially we can get rid of this handling of warnings.
      warning = doc.at_xpath("/reply/warning").try(:text)
      ignore_warning = %r{PLEASE NOTICE: the URL you are using for this service is not yet official}.match(warning.to_s)

      if ignore_warning
        Rails.logger.tagged("GeodisWarning") { Rails.logger.warn(warning) }
      end

      new(
        status: doc.at_xpath("/reply/status").try(:text),
        received_time: doc.at_xpath("/reply/received-time").try(:text),
        message: doc.at_xpath("/reply/msg").try(:text),
        warning: ignore_warning ? nil : warning,
        sli_no: doc.at_xpath("/reply/slino").try(:text),
        awb_no: doc.at_xpath("/reply/awbno").try(:text),
        base64_encoded_label_data: doc.at_xpath("/reply/labeldata").try(:text),
      )
    rescue Nokogiri::XML::SyntaxError => e
      ExceptionMonitoring.report(e)
      new(status: "0", message: "Unknown error")
    rescue => e
      ExceptionMonitoring.report(e)
      new(status: "0", message: "Unknown error")
    end
  end

  attr_accessor :status
  attr_accessor :received_time
  attr_accessor :message
  attr_accessor :warning
  attr_accessor :sli_no
  attr_accessor :awb_no
  attr_accessor :label_data

  def initialize(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end
  end

  def base64_encoded_label_data=(value)
    self.label_data = value ? Base64.decode64(value) : nil
  end

  def label?
    !label_data.nil?
  end

  def no_label?
    !label?
  end

  def generate_temporary_awb_pdf_file(&block)
    tmp_file = Tempfile.new([awb_no || "UNKNOWN_AWB_NO", ".pdf"])
    tmp_file.binmode
    tmp_file.write(label_data)
    tmp_file.rewind

    yield tmp_file.path
  ensure
    tmp_file.close
    tmp_file.unlink
  end

  def ok?
    status == "1"
  end

  def error?
    status == "0"
  end

  def pickup_error?
    %r{error\(s\) when trying to book PICK-UP}.match(warning) if warning
  end
end
