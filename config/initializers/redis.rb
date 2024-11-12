require 'redis'

REDIS_CLIENT = Redis.new(
  url: ENV.fetch("REDIS_URL") { "redis://redis:6379/0" },
  timeout: 1.0,
  reconnect_attempts: 5
) 