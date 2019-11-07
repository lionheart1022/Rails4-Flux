require "test_helper"
require "tempfile"
require "html2pdf"

class HTML2PDFTest < ActiveSupport::TestCase
  test "initialization" do
    # If this test fails it probably means `wkhtmltopdf` is not installed.
    assert_nothing_raised(HTML2PDF::ExecutableNotFound) do
      HTML2PDF.new("<html><body><h1>Heading 1</h1><p>A paragraph right here!</p></body></html>")
    end
  end

  test "#generate_pdf_and_write_to_file" do
    html2pdf = nil

    # If this test fails it probably means `wkhtmltopdf` is not installed.
    assert_nothing_raised(HTML2PDF::ExecutableNotFound) do
      html2pdf = HTML2PDF.new("<html><body><h1>Heading 1</h1><p>A paragraph right here!</p></body></html>")
    end

    begin
      tempfile = Tempfile.new(["test", ".pdf"], Rails.root.join("tmp"))

      assert tempfile.size == 0

      html2pdf.generate_pdf_and_write_to_file(tempfile.path)
      tempfile.rewind

      assert tempfile.size > 0
    ensure
      tempfile.close
      tempfile.unlink
    end
  end
end
