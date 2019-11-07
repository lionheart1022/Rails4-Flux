class GS1NumberSeries < NumberSeries
  class << self
    def next_sscc_number!
      this_sscc_number = nil

      transaction do
        number_series = active.lock(true).first
        raise "No active number series was found" unless number_series

        # TODO: We should check if we have exceeded the max - if we have the number series should be disabled.

        this_sscc_number = number_series.sscc_number

        # Increment series for _next_ time
        number_series.increment!(:next_value)
      end

      this_sscc_number
    end
  end

  KEY_OUR_PREFIX = "our_prefix(1)"
  KEY_GS1_PREFIX = "gs1_prefix(7)"

  validates :our_prefix, :gs1_prefix, presence: true, numericality: { only_integer: true }
  validates :our_prefix, length: { is: 1 }
  validates :gs1_prefix, length: { is: 7 }

  def our_prefix
    metadata && metadata[KEY_OUR_PREFIX]
  end

  def our_prefix=(value)
    self.metadata ||= {}
    self.metadata[KEY_OUR_PREFIX] = value
  end

  def gs1_prefix
    metadata && metadata[KEY_GS1_PREFIX]
  end

  def gs1_prefix=(value)
    self.metadata ||= {}
    self.metadata[KEY_GS1_PREFIX] = value
  end

  def sscc_number
    n = "#{our_prefix}#{gs1_prefix}#{next_value.to_s.rjust(9, '0')}"
    check_digit = calculate_check_digit(n)

    "#{n}#{check_digit}"
  end

  private

  # TODO: This method is copied from `GLSFeedbackFile` - consider extracting to separate class/module.
  # The method can be found at: https://www.gs1.org/services/how-calculate-check-digit-manually
  def calculate_check_digit(identifier)
    sum = 0

    identifier.chars.reverse.each_with_index do |c, i|
      multiplier = (i % 2) == 0 ? 3 : 1 # Alternate between 3 and 1 (starting with 3 for the least significant digit)
      sum += Integer(c)*multiplier
    end

    # Subtract the sum from nearest equal or higher multiple of ten
    sum.fdiv(10).ceil*10 - sum
  end
end
