class ExceptionMonitoring
  class << self
    def report_exception(exception, context: {})
      Raven.capture_exception(exception, extra: context)
    end

    alias_method :report, :report_exception

    def report_exception!(exception, context: {}, raise_in_environments: %w{development test})
      if raise_in_environments.include?(Rails.env)
        raise exception
      else
        report_exception(exception, context: context)
      end
    end

    alias_method :report!, :report_exception!

    def report_message(message, context: {})
      Raven.capture_message(message, extra: context)
    end
  end
end
