if ENV['OTEL_EXPORTER_OTLP_ENDPOINT']
  require 'opentelemetry/sdk'
  require 'opentelemetry/exporter/otlp'
  require 'opentelemetry/instrumentation/rails'
  require 'opentelemetry/instrumentation/active_support/span_subscriber'

  OpenTelemetry::SDK.configure do |config|
    config.service_name = ENV.fetch('OTEL_SERVICE_NAME', 'wrestlingdev')
    config.use_all
  end

  cable_tracer = OpenTelemetry.tracer_provider.tracer('wrestlingdev.cable')
  OpenTelemetry::Instrumentation::ActiveSupport.subscribe(cable_tracer, 'cable.broadcast.wrestlingdev')
  OpenTelemetry::Instrumentation::ActiveSupport.subscribe(cable_tracer, 'perform_action.action_cable')
  OpenTelemetry::Instrumentation::ActiveSupport.subscribe(cable_tracer, 'transmit.action_cable')
end
