# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    {
      time: event.time,
      remote_ip: event.payload[:remote_ip],
      user_id: event.payload[:user_id],
      params: event.payload[:params].except(*Rails.application.config.filter_parameters),
      exception: event.payload[:exception]&.first,
      exception_message: event.payload[:exception]&.last
    }
  end
end




