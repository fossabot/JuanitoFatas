FastlyRails.configure do |config|
  config.api_key = ENV["FASTLY_API_KEY"]
  config.max_age = 86400
  config.stale_while_revalidate = 86400
  config.stale_if_error = 86400
  config.service_id = ENV["SERVICE_ID"]
  config.purging_enabled = !Rails.env.development?
end
