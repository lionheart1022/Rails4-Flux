module FormHelper
  def disable_field_error_proc
    default_field_error_proc = ::ActionView::Base.field_error_proc

    begin
      ::ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| html_tag.html_safe }
      yield
    ensure
      ::ActionView::Base.field_error_proc = default_field_error_proc
    end
  end

  def render_form_error(form, attribute)
    if form.object.errors.key?(attribute)
      content_tag :div, form.object.errors.full_messages_for(attribute).first, class: "form-input-error"
    end
  end
end
