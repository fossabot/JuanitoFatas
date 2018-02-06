SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true, # mark all cookies as "Secure"
    httponly: true, # mark all cookies as "HttpOnly"
    samesite: {
      strict: true # mark all cookies as SameSite=Strict
    }
  }
  config.hsts = "max-age=631152000; includeSubdomains; preload" # 20.years
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "origin-when-cross-origin"
  config.csp = {
    # "meta" values. these will shaped the header, but the values are not included in the header.
    preserve_schemes: true, # default: false. Schemes are removed from host sources to save bytes and discourage mixed content.

    # directive values: these values will directly translate into source directives
    default_src: %w(https: 'self'),
    child_src: %w('self' *.twimg.com itunes.apple.com),
    connect_src: %w('self' wss:),
    font_src: %w(fonts.gstatic.com 'self' data:),
    img_src: %W(#{ENV["WWW_HOSTNAME"]} www.google-analytics.com cloud.githubusercontent.com twemoji.maxcdn.com avatars3.githubusercontent.com assets-cdn.github.com data:),
    media_src: %w(),
    object_src: %w('self'),
    script_src: %W(#{ENV["WWW_HOSTNAME"]} www.google-analytics.com 'unsafe-inline'),
    style_src: %W(#{ENV["WWW_HOSTNAME"]} fonts.googleapis.com 'unsafe-inline'),
    base_uri: %w('self'),
    form_action: %w('self' github.com),
    frame_ancestors: %w('none'),
    plugin_types: %w(application/x-shockwave-flash),
    block_all_mixed_content: true, # see http://www.w3.org/TR/mixed-content/
    upgrade_insecure_requests: true, # see https://www.w3.org/TR/upgrade-insecure-requests/
    report_uri: %w(https://report-uri.io/example-csp)
  }
  config.csp_report_only = config.csp
end
