module AdminNavigationHelper
  def nav_link(this_nav, text, link, options = {})
    active = Array(this_nav).include?(@current_nav)

    options[:class] = Array(options[:class])
    options[:class] << "sel" if active

    content_tag(:li, options) do
      link_to(text, link)
    end
  end

  def nav_link_with_badge(current_nav, text, link, badge_count:)
    link_content =
      if badge_count && badge_count > 0
        safe_join([text, content_tag(:span, badge_count, class: "navigation_badge")], " ")
      else
        text
      end

    nav_link(current_nav, link_content, link)
  end
end
