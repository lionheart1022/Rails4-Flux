require "net/ftp"
require "tempfile"

module UPSBillingFTP
  class << self
    def list_ftp_files(ftp_uri:)
      files = nil

      Net::FTP.open(ftp_uri.host, ftp_uri.user, ftp_uri.password) do |ftp|
        ftp.passive = true
        files = ftp.nlst
      end

      files
    end

    def parse_zip_from_ftp(ftp_uri:, file_name:)
      tmp_zip = Tempfile.new(["ups_billing", ".zip"])
      tmp_zip.binmode

      Net::FTP.open(ftp_uri.host, ftp_uri.user, ftp_uri.password) do |ftp|
        ftp.passive = true
        ftp.getbinaryfile(file_name, tmp_zip.path)
      end

      tmp_zip.rewind

      parse_result = nil

      Rails.logger.tagged("UPSBilling", SecureRandom.uuid) do
        Rails.logger.info "Analyzing ZIP file #{file_name}"
        parse_result = parse_zip(tmp_zip.path)
      end

      parse_result
    end

    def parse_zip(zip_path)
      parsed_files = {}

      Zip::File.open(zip_path) do |zip_file|
        zip_file.glob('*.xml').each do |entry|
          Rails.logger.info "Reading #{entry.name}"

          parsed_files[entry.name] = UPSBillingXMLFile.parse_xml(entry.get_input_stream.read)
        end
      end

      parsed_files
    end
  end
end
