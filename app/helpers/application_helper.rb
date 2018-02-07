module ApplicationHelper
  def links_to(text, url, options = {})
    link_to(
      text,
      url,
      options.merge(
        target: "_blank",
        rel: "noopener",
        itemprop: "url"
      )
    )
  end
end
