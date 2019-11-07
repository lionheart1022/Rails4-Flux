require "net/ftp"

class GLSDaily
  attr_accessor :ftp_uri
  attr_accessor :dry_run
  attr_accessor :delete_processed_file
  attr_reader :created_feedback_files

  alias_method :delete_processed_file?, :delete_processed_file
  alias_method :dry_run?, :dry_run

  SOURCE_DIR = "/daily"

  def initialize(ftp_uri: nil, dry_run: true)
    self.ftp_uri ||= URI(ENV.fetch("GLS_DAILY_FTP_URI"))
    self.dry_run = dry_run
  end

  def perform!
    @created_feedback_files = []

    setup_ftp!

    new_files.each do |new_file|
      download_new_file(new_file)
      delete_new_file(new_file)
    end

    nil
  ensure
    ftp.close if ftp
  end

  private

  attr_reader :ftp

  def setup_ftp!
    @ftp = Net::FTP.open(ftp_uri.host)
    @ftp.passive = true
    @ftp.login(ftp_uri.user, ftp_uri.password)
    @ftp.chdir(SOURCE_DIR)
    @ftp
  end

  def new_files
    files_per_account = {}

    ftp.nlst.each do |filename|
      match = %r{\A(?<account_number>\d{5})\.(?<timestamp>.+)\z}.match(filename)

      if match.nil?
        message = "Unexpected GLS daily file (#{filename})"
        ExceptionMonitoring.report_message(message, context: {})
        Rails.logger.warn message
        next
      end

      account_number, timestamp = match[:account_number], match[:timestamp]
      configuration = GLSFeedbackConfiguration.with_account_number(account_number).first

      if configuration
        files_per_account[account_number] ||= []
        files_per_account[account_number] << NewFile.new(configuration, filename, timestamp)
      else
        Rails.logger.warn "Could not find GLS feedback config for account number #{account_number}"
      end
    end

    # Sort new files by timestamp so we process the filenames in the correct order (oldest first).
    files_per_account.each do |_, files|
      files.sort_by! { |file| file.timestamp }
    end

    files_per_account.values.flatten
  end

  def download_new_file(new_file)
    ActiveRecord::Base.transaction do
      feedback_file_relation = new_file.feedback_file_relation

      if feedback_file_relation.empty?
        feedback_file = feedback_file_relation.new

        remote_file_contents = ftp.getbinaryfile(feedback_file.original_filename, nil)
        remote_file_io = StringIO.new(remote_file_contents)

        if dry_run?
          Rails.logger.info "Would have registered file #{new_file.filename} for GLS customer (#{new_file.configuration.account_label})"
        else
          Rails.logger.info "Registering file #{new_file.filename} for GLS customer (#{new_file.configuration.account_label})"

          feedback_file.attach_file(remote_file_io); remote_file_io.rewind
          feedback_file.assign_file_contents(remote_file_io)
          feedback_file.save!

          @created_feedback_files << feedback_file

          new_file.configuration.update!(latest_file: feedback_file)
        end
      else
        Rails.logger.info "Skipping existing file #{new_file.filename} for GLS customer (#{new_file.configuration.account_label})"
      end
    end
  end

  def delete_new_file(new_file)
    if delete_processed_file?
      if dry_run?
        Rails.logger.info "Would have deleted file #{new_file.filename}"
      else
        Rails.logger.info "Deleting file #{new_file.filename}"
        ftp.delete(new_file.filename)
      end
    end
  end

  NewFile = Struct.new(:configuration, :filename, :timestamp) do
    def feedback_file_relation
      GLSFeedbackFile.where(configuration: configuration, company: configuration.company, original_filename: filename)
    end
  end
end
