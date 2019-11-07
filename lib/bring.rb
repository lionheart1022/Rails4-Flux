require "cgi"

class Bring
  class << self
    def track_and_trace_url(awb:)
      "http://tracking.bring.com/tracking.html?q=#{CGI.escape(awb)}"
    end
  end
end
