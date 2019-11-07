require "net/ftp"
require "tempfile"

class UPSFeedbackConfiguration < CarrierFeedbackConfiguration
  def carrier_name
    "UPS"
  end

  def account_label
    "Account: #{account_details['account_number']}"
  end

  def carrier_type
    :ups
  end

  def ftp_uri
    URI("ftp://#{ftp_username}:#{ftp_password}@#{ftp_host}")
  end

  def ftp_host
    credentials["ftp_host"]
  end

  def ftp_username
    credentials["ftp_username"]
  end

  def ftp_password
    credentials["ftp_password"]
  end

  def download_zip_from_ftp!(zip_file_name)
    tmp_zip = Tempfile.new(["ups_billing", ".zip"])
    tmp_zip.binmode

    Net::FTP.open(ftp_host, ftp_username, ftp_password) do |ftp|
      ftp.passive = true
      ftp.getbinaryfile(zip_file_name, tmp_zip.path)
    end

    tmp_zip.rewind

    feedback_file = UPSFeedbackFile.new(configuration: self, company: company)

    transaction do
      Zip::File.open(tmp_zip.path) do |zip_file|
        zip_file.glob('*.xml').each do |entry|
          if feedback_file.persisted?
            raise "Found more UPS XML Billing files in ZIP than expected"
          end

          remote_file_contents = entry.get_input_stream.read
          remote_file_io = StringIO.new(remote_file_contents)
          combined_file_name = "#{zip_file_name}--#{entry.name}"

          feedback_file.original_filename = combined_file_name
          feedback_file.attach_file(remote_file_io); remote_file_io.rewind
          feedback_file.assign_file_contents(remote_file_io)
          feedback_file.save!
        end
      end
    end

    feedback_file
  end
end
