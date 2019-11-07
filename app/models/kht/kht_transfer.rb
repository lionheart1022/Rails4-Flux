require "net/ftp"

class KHTTransfer
  attr_accessor :message
  attr_accessor :file_name
  attr_accessor :ftp_user
  attr_accessor :ftp_host
  attr_accessor :ftp_password

  class << self
    def perform!(*args)
      transfer = new(*args)
      transfer.perform!
      transfer
    end
  end

  def initialize(params = {})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end

    self.file_name ||= "booking-from-cf_#{SecureRandom.hex(4)}.xml"
  end

  def perform!
    local_tempfile = Tempfile.new("kht-booking", encoding: "Windows-1252")
    local_tempfile.write(xml_message)
    local_tempfile.rewind
    local_tempfile.close

    local_file_path = local_tempfile.path

    begin
      Net::FTP.open(ftp_host, ftp_user, ftp_password) do |ftp|
        ftp.passive = true

        ftp.puttextfile(local_file_path, file_name)

        Rails.logger.tagged("KHTTransfer") do
          Rails.logger.info "*" * 80
          Rails.logger.info xml_message
          Rails.logger.info "*" * 80
        end
      end

      true
    ensure
      local_tempfile.close
      local_tempfile.unlink
    end
  end

  def xml_message
    @xml_message ||= message.to_xml
  end
end
