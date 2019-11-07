class LayoutConfig
  class << self
    def new_from_company(company)
      new.tap do |config|
        config.company = company
        config.title = company.name
        config.primary_brand_color = company.primary_brand_color
      end
    end

    def new_generic
      new.tap do |config|
        config.title = "CargoFlux"
      end
    end
  end

  attr_accessor :company
  attr_accessor :title
  attr_accessor :body_class
  attr_accessor :root_path
  attr_accessor :primary_brand_color

  def custom_css
    return "" if primary_brand_color.blank?

    <<-CSS
      #app_header {
        background-color: #{primary_brand_color};
        border-bottom-color: #{app_header_border_color};
      }

      ul.actions li.primary a,
      ul.actions li.primary input[type="submit"],
      input[type="submit"].primary-btn,
      button.primary-btn,
      a.primary-btn {
        background-color: #{btn_gradient_start_color};
        background-image: -webkit-gradient(linear, left top, left bottom, from(#{btn_gradient_start_color}), to(#{btn_gradient_end_color}));
        background-image: -webkit-linear-gradient(top, #{btn_gradient_start_color}, #{btn_gradient_end_color});
        background-image: -moz-linear-gradient(top, #{btn_gradient_start_color}, #{btn_gradient_end_color});
        background-image: -ms-linear-gradient(top, #{btn_gradient_start_color}, #{btn_gradient_end_color});
        background-image: -o-linear-gradient(top, #{btn_gradient_start_color}, #{btn_gradient_end_color});
        background-image: linear-gradient(to bottom, #{btn_gradient_start_color}, #{btn_gradient_end_color});
        filter: progid:DXImageTransform.Microsoft.gradient(gradientType=0, startColorstr='\#{ie-hex-str(#{btn_gradient_start_color})}', endColorstr='\#{ie-hex-str(#{btn_gradient_end_color})}');

        border-color: #{btn_border_color};
      }

      #navigation li.sel a,
      #navigation a:hover {
        color: #{selected_nav_text_color};
      }

      .navigation_badge {
        background: #{nav_badge_bg_color};
      }

      #secondary_nav a {
        text-shadow: -1px 0 1px #{header_text_shadow_color}, 0 1px 1px #{header_text_shadow_color}, 1px 0 1px #{header_text_shadow_color}, 0 -1px 1px #{header_text_shadow_color};
      }

      .app_header_title_container a {
        text-shadow: -1px 0 1px #{header_text_shadow_color}, 0 1px 1px #{header_text_shadow_color}, 1px 0 1px #{header_text_shadow_color}, 0 -1px 1px #{header_text_shadow_color};
      }
    CSS
  end

  def btn_gradient_start_color
    rgb_match = /#(\h\h)(\h\h)(\h\h)/.match(primary_brand_color)
    tint = 0.40

    if rgb_match
      color_code_without_pound_sign =
        rgb_match
        .captures
        .map { |c| c.to_i(16) }
        .map { |v| v + (255 - v)*tint }
        .map { |v| sprintf("%02x", v.round) }
        .join

      "##{color_code_without_pound_sign}".downcase
    else
      primary_brand_color # Fallback
    end
  end

  def btn_gradient_end_color
    primary_brand_color
  end

  def btn_border_color
    primary_brand_color_with_shade(0.75)
  end

  def selected_nav_text_color
    primary_brand_color
  end

  def nav_badge_bg_color
    primary_brand_color
  end

  def app_header_border_color
    primary_brand_color_with_shade(0.50)
  end

  def header_text_shadow_color
    primary_brand_color_with_shade(0.50)
  end

  private

  def primary_brand_color_with_shade(shade)
    rgb_match = /#(\h\h)(\h\h)(\h\h)/.match(primary_brand_color)

    if rgb_match
      color_code_without_pound_sign =
        rgb_match
        .captures
        .map { |c| c.to_i(16) }
        .map { |v| v*shade }
        .map { |v| sprintf("%02x", v.round) }
        .join

      "##{color_code_without_pound_sign}".downcase
    else
      primary_brand_color # Fallback
    end
  end
end
