require "securerandom"

class TokenSession < ActiveRecord::Base
  belongs_to :company, required: true
  belongs_to :sessionable, required: true, polymorphic: true

  scope :active, -> { where expired_at: nil }

  validates :token_value, presence: true

  class << self
    def create_and_generate_unique_token!(*args)
      session = new(*args)

      retries = 0
      max_retries = 5

      transaction do
        begin
          session.generate_and_assign_new_token
          session.save!
        rescue ActiveRecord::RecordNotUnique
          if (retries += 1) < max_retries
            retry
          else
            raise
          end
        end
      end

      session
    end
  end

  def user_email
  end

  def expired?
    expired_at?
  end

  def active?
    !expired?
  end

  def expire!(reason: nil)
    if expired_at.nil?
      update!(expired_at: Time.zone.now, expiration_reason: reason)
    end
  end

  def register_usage!
    update!(last_used_at: Time.zone.now)
  end

  def generate_and_assign_new_token
    self.token_value = generate_secure_token
  end

  def generate_secure_token
    SecureRandom.urlsafe_base64
  end
end
