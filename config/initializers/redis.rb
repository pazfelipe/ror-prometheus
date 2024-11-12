require 'redis'

REDIS_CLIENT = Redis.new(
  url: ENV.fetch("REDIS_URL") { "redis://redis:6379/0" },
  reconnect_attempts: 5,
  reconnect_delay: 1.0,
  reconnect_delay_max: 2.0
) 