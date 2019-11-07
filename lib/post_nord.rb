require "cgi"

class PostNord
  class << self
    def track_and_trace_url(awb:)
      "http://www.postnord.dk/track-trace#dynamicloading=true&shipmentid=#{CGI.escape(awb)}"
    end
  end
end
