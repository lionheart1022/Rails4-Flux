require 'open3'

class HTML2PDF
  attr_reader :html
  attr_reader :exe_path

  DEFAULT_PATH_TO_WKHTMLTOPDF =
    if Rails.env.staging? || Rails.env.production?
      Rails.root.join('bin', 'wkhtmltopdf_0.12.5-1.trusty_amd64').to_s
    else
      'wkhtmltopdf'
    end

  def initialize(html, exe_path: nil)
    @html = html
    @exe_path = exe_path || default_exe_path

    check_exe_path!
  end

  def generate_pdf_and_write_to_file(output_path, timeout_sec: 10)
    pdf = nil

    Timeout.timeout(timeout_sec, ExecutionTimeoutError) do
      pdf = capture_pdf!
    end

    File.open(output_path, 'wb') do |f|
      f.write(pdf)
    end
  end

  private

  def capture_pdf!
    stdout_str, stderr_str, status = capture

    if status.exitstatus != 0
      raise ExecutionError.new("wkhtmltopdf exited with unexpected status #{status.exitstatus}", context: { "stderr" => stderr_str })
    end

    stdout_str
  end

  def capture
    command_opts = '--quiet --zoom 1.3 --page-size A4'
    command = "#{exe_path} #{command_opts} - -"
    Open3.capture3(command, stdin_data: html)
  end

  def default_exe_path
    ENV.fetch('PATH_TO_WKHTMLTOPDF', DEFAULT_PATH_TO_WKHTMLTOPDF)
  end

  def check_exe_path!
    stdout_str, _stderr_str, _status = Open3.capture3("#{exe_path} --version")

    return true if stdout_str =~ /wkhtmltopdf .+\..+\..+/

    raise ExecutableNotFound, "Unexpected executable: #{exe_path}"
  rescue Errno::ENOENT
    raise ExecutableNotFound, "Could not find executable: #{exe_path}"
  end

  class ExecutableNotFound < StandardError
  end

  class ExecutionTimeoutError < StandardError
  end

  class ExecutionError < StandardError
    attr_reader :context

    def initialize(message, context: {})
      @context = context
      super(message)
    end
  end
end
