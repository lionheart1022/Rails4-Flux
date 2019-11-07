module ApplicationHelper
  def newline_html_formatted(string)
    if string.present?
      string.gsub(/\n/, '<br/>').html_safe
    end
  end

  def fractional_formatted(value)
    whole_integer = value.floor
    remainder = value - whole_integer

    if value == 0
      "0"
    elsif whole_integer == 0
      fraction_to_html(remainder)
    elsif remainder == 0
      "#{whole_integer}"
    else
      "#{whole_integer} #{fraction_to_html(remainder)}".html_safe
    end
  end

  def fraction_to_html(value)
    r = value.rationalize
    "#{r.numerator}&frasl;#{r.denominator}".html_safe
  end

  def indicator_link_to(specified, text, url)
    link_to(url, class: "link-with-indicator") do
      safe_join([
        content_tag(:span, "", class: "link-with-indicator--#{specified ? 'specified' : 'blank'}"),
        " ",
        content_tag(:span, text, class: "link-with-indicator--inner-text"),
      ])
    end
  end

  def copyright_text
    "Copyright © 2018 CargoFlux"
  end
end
