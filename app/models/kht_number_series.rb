class KHTNumberSeries < NumberSeries
  class << self
    def next_waybill_number!
      number_series = nil
      this_waybill_number = nil

      transaction do
        number_series = active.lock(true).first
        raise "No active number series was found" unless number_series

        if number_series.next_value > number_series.max_value
          number_series.touch(:disabled_at)
        else
          this_waybill_number = number_series.waybill_number

          # Increment series for _next_ time
          number_series.increment!(:next_value)
        end
      end

      if number_series.disabled_at?
        raise "KHT number series has reached max value"
      end

      this_waybill_number
    end
  end

  def waybill_number
    next_value.to_s.rjust(8, '0')
  end
end
