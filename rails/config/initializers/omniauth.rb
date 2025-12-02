OmniAuth.configure do |config|
  config.allowed_request_methods = [:post, :get]
  config.silence_get_warning = true
  config.full_host = ENV['RAILS_FORCE_SSL'] == 'true' ? "https://#{ENV['RAILS_HOST']}" : "http://#{ENV['RAILS_HOST']}"
end