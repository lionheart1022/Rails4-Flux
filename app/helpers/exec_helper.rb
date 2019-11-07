module ExecHelper
  def exec_nav_section(identifier)
    section_classes = %w(app-nav-section)
    section_classes << "active" if Array(cached_active_nav)[0] == identifier

    content_tag(:div, class: section_classes) do
      yield
    end
  end
end
