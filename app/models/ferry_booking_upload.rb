class FerryBookingUpload < ActiveRecord::Base
  belongs_to :company, required: true

  validates :file_path, presence: true
  validates :document, presence: true

  def sftp_upload!(host:, user:, password:)
    Net::SFTP.start(host, user, password: password) do |sftp|
      io = StringIO.new(document)
      sftp.upload!(io, file_path)
    end
  end
end
