module StatesPerCountry
  CountryEntry = Struct.new(:code, :states) do
    def country_code
      code
    end
  end

  StateEntry = Struct.new(:name, :code) do
    def state_code
      code
    end

    def full_state_name
      @_full_state_name ||= "#{name} (#{code})"
    end
  end

  COUNTRY_CODES = %w(us ca)

  module_function
    def state_objects_for_country(code:)
      Country
        .find_country_by_alpha2(code)
        .states
        .map { |code, state_struct| StateEntry.new(state_struct.name, code) }
    end

  # Memoize the array
  mattr_reader :as_array do
    COUNTRY_CODES.map do |country_code|
      CountryEntry.new(country_code, state_objects_for_country(code: country_code))
    end
  end
end
