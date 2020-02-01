require "redis"
require "redis/connection/hiredis"
require "oj"

module Ezmetrics
  require_relative "ezmetrics/version"
  require_relative "ezmetrics/storage"
  require_relative "ezmetrics/benchmark"

  if defined?(Rails)
    require_relative "ezmetrics/dashboard/lib/dashboard"
  end
end