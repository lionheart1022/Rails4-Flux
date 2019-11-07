class FerryProductIntegration < ActiveRecord::Base
  class << self
    def setting_attr_accessor(*attrs)
      attrs.each do |attr|
        define_method(attr) do
          read_setting(attr)
        end

        define_method("#{attr}?") do
          read_setting(attr).present?
        end

        define_method("#{attr}=") do |value|
          write_setting(attr, value)
        end
      end
    end
  end

  belongs_to :company, required: true

  setting_attr_accessor :account_number, :scandlines_id, :sftp_host, :sftp_user, :sftp_password

  def ready_for_use?
    account_number? && scandlines_id? && sftp_host? && sftp_user? && sftp_password?
  end

  private

  def write_setting(key, value)
    self.settings ||= {}
    self.settings[key.to_s] = value
  end

  def read_setting(key)
    settings[key.to_s] if settings
  end
end
