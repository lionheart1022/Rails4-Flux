require "html2pdf"

class TNTPrint
  class BaseError < StandardError; end
  class PDFGenerationTimeoutError < BaseError; end
  class StylesheetError < BaseError; end
  class StylesheetNetworkError < StylesheetError; end

  attr_reader :xml
  attr_reader :output_html

  def initialize(xml_string: nil, xml_document: nil)
    @xml = xml_document || Nokogiri::XML(xml_string)
    raise ArgumentError, "`xml_string` or `xml_document` should be set" if @xml.nil?
  end

  def generate_html!
    xslt = Nokogiri::XSLT(fetch_stylesheet)
    transformed_xml = xslt.transform(xml)

    # Replace back-slashes with forward-slashes in img src-attributes.
    transformed_xml.css('img[src*="\"]').each do |node|
      node["src"] = node["src"].gsub("\\", "/")
    end

    @output_html = transformed_xml.to_html
    @output_html.encode!("UTF-8")
    @output_html.sub!(%q[<META http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">], %q[<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">])
    @output_html.sub!(%q[<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">], %q[<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">])

    @output_html
  end

  def generate_pdf!(output_path, timeout_sec: 10)
    generate_html!

    html2pdf = HTML2PDF.new(output_html)
    html2pdf.generate_pdf_and_write_to_file(output_path, timeout_sec: timeout_sec)
  end

  private

  def fetch_stylesheet
    stylesheet_processing_instruction = xml.at_xpath('//processing-instruction("xml-stylesheet")')

    if stylesheet_processing_instruction.nil?
      raise StylesheetError, "No xml-stylesheet processing instruction was found"
    end

    stylesheet_url_match = stylesheet_processing_instruction.content.match(/href="(?<url>[^"]*)"/)

    if stylesheet_url_match.nil?
      raise StylesheetError, "No `href` was found for the xml-stylesheet processing instruction"
    end

    stylesheet_url = stylesheet_url_match[:url]
    stylesheet_http_response = Net::HTTP.get_response(URI(stylesheet_url))

    if stylesheet_http_response.is_a?(Net::HTTPSuccess)
      fix_xslt(stylesheet_http_response.body)
    else
      raise StylesheetNetworkError, "Could not fetch stylesheet"
    end
  end

  def fix_xslt(input)
    # As of July 20th 2018 TNT has reverted to not use this invalid `msxml:node-set` function.
    # We'll keep this here for future reference if they were to introduce this again.

    input
      .sub('"msxml:node-set($lookup)"', '"_"')
  end
end
