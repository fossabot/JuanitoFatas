# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"

Bundler.require(*Rails.groups)

module Juanitofatas
  class Application < Rails::Application
    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      r301 "/2015/05/19/rubygem-configuration-pattern", "/blog/2015/05/19/rubygem_configuration_pattern"
    end
  end
end
