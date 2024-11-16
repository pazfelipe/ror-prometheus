Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      resources :todos
    end
  end

  # Prometheus metrics endpoint
  get '/metrics', to: proc {
    registry = Prometheus::Client.registry
    output = []
    
    registry.metrics.each do |metric|
      output << "# HELP #{metric.name} #{metric.docstring}"
      output << "# TYPE #{metric.name} #{metric.type}"
      
      case metric.type
      when :counter, :gauge
        if metric.values
          metric.values.each do |labels, value|
            output << format_metric(metric.name, labels, value)
          end
        end
      when :histogram
        if metric.values
          metric.values.each do |labels, value|
            next unless value.is_a?(Hash)
            
            # Buckets
            buckets = value[:bucket] || {}
            buckets.each do |le, count|
              output << format_metric("#{metric.name}_bucket", labels.merge(le: le.to_s), count.to_i)
            end
            
            # Add +Inf bucket with total count
            output << format_metric("#{metric.name}_bucket", labels.merge(le: "+Inf"), value[:count].to_i)
            
            # Sum and count
            output << format_metric("#{metric.name}_sum", labels, value[:sum].to_f)
            output << format_metric("#{metric.name}_count", labels, value[:count].to_i)
          end
        end
      end
    end
    
    [200, {'Content-Type' => 'text/plain'}, [output.join("\n")]]
  }
end

def format_metric(name, labels, value)
  if labels.empty?
    "#{name} #{value}"
  else
    labels_str = labels.map { |k, v| %Q(#{k}="#{v}") }.join(',')
    "#{name}{#{labels_str}} #{value}"
  end
end
