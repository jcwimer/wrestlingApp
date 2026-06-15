if ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
  require 'opentelemetry/sdk'
  require 'opentelemetry/exporter/otlp'
  require 'opentelemetry/instrumentation/rails'

  OpenTelemetry::SDK.configure do |config|
    config.service_name = ENV.fetch('OTEL_SERVICE_NAME', 'wrestlingdev')
    config.use_all
  end
end
