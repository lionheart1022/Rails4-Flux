require "net/ftp"

class DSVBookingTransfer
  attr_accessor :message
  attr_accessor :file_name
  attr_accessor :ftp_uri

  def initialize(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end

    self.ftp_uri ||= URI(ENV.fetch("DSV_FTP_URI"))
    self.file_name ||= "booking-from-cf_#{SecureRandom.hex(4)}.txt"
  end

  def perform!
    local_tempfile = Tempfile.new("dsv-booking")
    local_tempfile.write(message.as_edifact)
    local_tempfile.rewind
    local_tempfile.close

    local_file_path = local_tempfile.path

    begin
      Net::FTP.open(ftp_host, ftp_username, ftp_password) do |ftp|
        ftp.passive = true

        ftp.chdir("/inbox")
        ftp.puttextfile(local_file_path, file_name)

        Rails.logger.tagged("DSVBookingTransfer") do
          Rails.logger.info "*" * 80
          Rails.logger.info message.as_edifact
          Rails.logger.info "*" * 80
        end
      end

      true
    ensure
      local_tempfile.close
      local_tempfile.unlink
    end
  end

  private

  def ftp_host
    ftp_uri.host
  end

  def ftp_username
    ftp_uri.user
  end

  def ftp_password
    ftp_uri.password
  end
end
