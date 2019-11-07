class Companies::AnnouncementsController < CompaniesController
  helper_method :revision_title

  def index
    if check_revisions?
      html = render_to_string "companies/whats_new"
      check_revisions!(html)
      render text: html
    else
      render "companies/whats_new"
    end
  end

  private

  def revision_title(revision, date)
    date = date.is_a?(String) ? Date.parse(date) : date
    content = %Q[Release #{revision}: #{date.strftime('%A, %b %-d')}<sup>#{date.day.ordinal}</sup> #{date.strftime('%Y')}]

    if check_revisions?
      %Q[<span data-revision="#{revision}">#{content}</span>].html_safe
    else
      content.html_safe
    end
  end

  def check_revisions!(html)
    doc = Nokogiri::HTML(html)

    previous_revision = nil
    doc.css("[data-revision]").reverse_each do |node|
      current_revision = Integer(node["data-revision"])

      if previous_revision && previous_revision + 1 != current_revision
        raise "Revision was expected to be #{previous_revision + 1} for `#{node.text}`"
      end

      previous_revision = current_revision
    end
  end

  def check_revisions?
    Rails.env.development? || Rails.env.test?
  end
end
