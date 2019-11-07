module EconomicHelper
  def economic_refresh_button
    link_to(
      content_tag(:span, "↻"),
      companies_v2_economic_product_requests_path,
      method: :post,
      class: "refresh_economic_products",
      title: "Fetch latest products from e-conomic",
      remote: true,
      data: { behavior: "economic_product_select_refresh" },
    )
  end
end
