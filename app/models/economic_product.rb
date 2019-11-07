class EconomicProduct < ActiveRecord::Base
  belongs_to :access, class_name: "EconomicAccess", required: true

  validates :number, presence: true

  def option_name
    "#{no_longer_available? ? "[DEPRECATED] " : ""}#{number} #{name}"
  end
end
