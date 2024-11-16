class PrometheusMetricsMiddleware
  IGNORED_PATHS = ['/metrics'].freeze

  def initialize(app)
    @app = app
    @registry = Prometheus::Client.registry

    # Request duration histogram
    @http_request_duration = @registry.get(:http_request_duration_seconds) || begin
      histogram = Prometheus::Client::Histogram.new(
        :http_request_duration_seconds,
        docstring: 'HTTP request duration in seconds',
        labels: [:method, :path],
        buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
      )
      @registry.register(histogram)
      histogram
    end

    # Request counter
    @http_requests_total = @registry.get(:http_requests_total) || begin
      counter = Prometheus::Client::Counter.new(
        :http_requests_total,
        docstring: 'Total number of HTTP requests',
        labels: [:method, :path, :status]
      )
      @registry.register(counter)
      counter
    end

    # Database query duration
    @db_query_duration = @registry.get(:active_record_query_duration_seconds) || begin
      histogram = Prometheus::Client::Histogram.new(
        :active_record_query_duration_seconds,
        docstring: 'Active Record query duration in seconds',
        buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1.0]
      )
      @registry.register(histogram)
      histogram
    end

    # Redis operations counter
    @redis_operations = @registry.get(:redis_operations_total) || begin
      counter = Prometheus::Client::Counter.new(
        :redis_operations_total,
        docstring: 'Total number of Redis operations',
        labels: [:operation]
      )
      @registry.register(counter)
      counter
    end
  end

  def call(env)
    if IGNORED_PATHS.include?(env['PATH_INFO'])
      @app.call(env)
    else
      record_request_metrics(env)
    end
  end

  private

  def record_request_metrics(env)
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status, headers, response = @app.call(env)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

    path = normalize_request_path(env['PATH_INFO'])
    method = env['REQUEST_METHOD']

    # Increment request counter
    @http_requests_total.increment(
      labels: {
        method: method,
        path: path,
        status: status.to_s
      }
    )

    # Record request duration
    @http_request_duration.observe(
      duration,
      labels: {
        method: method,
        path: path
      }
    )

    # Observe database metrics
    if defined?(ActiveRecord::Base) && ActiveRecord::Base.connected?
      begin
        query_time = ActiveRecord::Base.connection.instance_variable_get(:@query_time)
        if query_time && query_time.to_f > 0
          query_duration = query_time.to_f
          @db_query_duration.observe(query_duration)
          Rails.logger.info "  - DB Query: duration=#{query_duration}s"
        end
      rescue => db_error
        Rails.logger.error "Error recording DB metrics: #{db_error.message}"
      end
    end

    [status, headers, response]
  end

  def normalize_request_path(path)
    path.gsub(%r{/\d+}, '/:id')
  end
end 