require "cgi"

class TNT
  class << self
    def track_and_trace_url(awb:)
      "https://www.tnt.com/track?cons=#{CGI.escape(awb)}&searchType=CON"
    end
  end
end
