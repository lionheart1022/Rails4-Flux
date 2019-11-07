require "cgi"

class DHL
  class << self
    def track_and_trace_url(awb:)
      "http://www.dhl.com/en/express/tracking.html?AWB=#{CGI.escape(awb)}&brand=DHL"
    end
  end
end
