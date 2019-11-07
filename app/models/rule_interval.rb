class RuleInterval < ActiveRecord::Base
  belongs_to :rule, class_name: "CarrierProductRule", required: true

  def include?(_value)
    raise "define in subclass"
  end
end
