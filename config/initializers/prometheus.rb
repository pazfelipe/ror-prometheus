require 'prometheus/client'
require 'prometheus_exporter/middleware'
require 'prometheus_exporter/instrumentation'

# Create a new registry
prometheus = Prometheus::Client.registry

# Create metrics
http_requests_total = Prometheus::Client::Counter.new(:http_requests_total, docstring: 'Total number of HTTP requests', labels: [:method, :path, :status])
http_request_duration_seconds = Prometheus::Client::Histogram.new(:http_request_duration_seconds, docstring: 'HTTP request duration in seconds', labels: [:method, :path])
active_record_query_duration_seconds = Prometheus::Client::Histogram.new(:active_record_query_duration_seconds, docstring: 'Active Record query duration in seconds')
redis_operations_total = Prometheus::Client::Counter.new(:redis_operations_total, docstring: 'Total number of Redis operations', labels: [:operation])

# Register metrics
prometheus.register(http_requests_total)
prometheus.register(http_request_duration_seconds)
prometheus.register(active_record_query_duration_seconds)
prometheus.register(redis_operations_total)

# Configuração básica do Prometheus Exporter
PrometheusExporter::Metric::Base.default_prefix = 'ruby_'

# Inicializa o client
PrometheusExporter::Client.default = PrometheusExporter::Client.new(
  host: 'localhost',
  port: 9394,
  custom_labels: { app: 'todo_api' }
)

# Adiciona instrumentação do processo
PrometheusExporter::Instrumentation::Process.start(
  type: 'web',
  labels: { app: 'todo_api' }
)

# Adiciona instrumentação do ActiveRecord
PrometheusExporter::Instrumentation::ActiveRecord.start(
  custom_labels: { app: 'todo_api' }
)

# Configura métricas personalizadas
PROMETHEUS_REQUEST_DURATION = PrometheusExporter::Metric::Histogram.new(
  'http_request_duration_seconds',
  'HTTP request duration in seconds'
)

PROMETHEUS_REQUEST_COUNT = PrometheusExporter::Metric::Counter.new(
  'http_requests_total',
  'Total number of HTTP requests'
)

PrometheusExporter::Client.default.register(PROMETHEUS_REQUEST_DURATION)
PrometheusExporter::Client.default.register(PROMETHEUS_REQUEST_COUNT) 