module CarrierConfig
  mattr_reader :config do
    YAML.load(File.read(Rails.root.join("config", "carriers.yml"))).with_indifferent_access
  end

  module_function
    def surcharges_for_carrier(carrier_identifier)
      config.fetch(carrier_identifier).fetch("surcharges")
    end
end
