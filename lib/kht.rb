require "cgi"

class KHT
  class << self
    def track_and_trace_url(awb:)
      "http://booking.kht.as/link/VisTT_kht.asp?tt=#{CGI.escape(awb)}"
    end
  end
end
