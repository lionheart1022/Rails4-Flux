class Companies::EconomicSettings::EditView
  attr_reader :main_view, :setting

  def initialize(setting: nil, products: nil)
    @setting = setting
    @products = products
    state_general
  end

  def products
    result = []
    @products.body["collection"].each do |obj|
      result << OpenStruct.new(
        :id            => obj["productNumber"],
        :name          => obj["name"],
        :product_group => obj["productGroup"]["name"]
      )
    end
    result
  end

  private

    def state_general
      @main_view = "components/companies/economic_settings/edit"
    end

end
