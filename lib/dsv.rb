require "cgi"

class DSV
  class << self
    def track_and_trace_url(awb:)
      "https://www.tracktrace.dsv.com/newtracking/public/PublicSearch.spr?sid=#{CGI.escape(awb)}&mode=reference&action=directSearch"
    end
  end
end
