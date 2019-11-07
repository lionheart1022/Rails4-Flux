class CarrierProductCredential < ActiveRecord::Base
  belongs_to :target, polymorphic: true, required: true
  belongs_to :owner, polymorphic: true

  class << self
    def credential_field(attr_name)
      define_method(attr_name) do
        self.credential_fields && self.credential_fields[String(attr_name)]
      end

      define_method("#{attr_name}=") do |value|
        self.credential_fields ||= {}
        self.credential_fields[String(attr_name)] = value.presence
      end
    end
  end

  def form_partial_path
    raise "Override in subclass"
  end

  def whitelist_params(credential_params)
    credential_params
  end

  def whitelist_and_assign_params(credential_params)
    assign_attributes(whitelist_params(credential_params))
  end

  def has_any_present_credential_fields?
    credential_fields && credential_fields.any? { |_, value| value.present? }
  end
end
