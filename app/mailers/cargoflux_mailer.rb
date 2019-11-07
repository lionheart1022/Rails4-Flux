class CargofluxMailer < ActionMailer::Base
  def company_from_email(company)
    company.info_email.present? ? company.info_email : ActionMailer::Base.default[:from]
  end

  helper do
    def text_formatted_goods_line(line:, goods:)
      "#{line.quantity} #{line.goods_identifier} x " \
        "#{number_with_precision(line.length, precision: 2, strip_insignificant_zeros: true)} #{goods.dimension_unit}, " \
        "#{number_with_precision(line.width, precision: 2, strip_insignificant_zeros: true)} #{goods.dimension_unit}, " \
        "#{number_with_precision(line.height, precision: 2, strip_insignificant_zeros: true)} #{goods.dimension_unit}, " \
        "#{number_with_precision(line.weight, precision: 2, strip_insignificant_zeros: true)} #{goods.weight_unit}, " \
        "#{goods.volume_type == 'loading_meter' ? 'LDM' : 'Volume weight'}: #{line.volume_weight ? number_with_precision(line.volume_weight, precision: 3) : ''}"
    end
  end
end
