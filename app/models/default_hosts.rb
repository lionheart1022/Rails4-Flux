module DefaultHosts
  def list
    string_value.split(",").map(&:strip).reject(&:blank?)
  end

  module_function :list

  private

  def string_value
    if Rails.env.development?
      ENV.fetch("DEFAULT_HOSTS", "localhost")
    elsif Rails.env.test?
      "www.example.com"
    else
      ENV.fetch("DEFAULT_HOSTS")
    end
  end

  module_function :string_value
end
