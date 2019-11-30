require "redis"
require "redis/connection/hiredis"
require "oj"

class EZmetrics
  METRICS               = [:duration, :views, :db, :queries].freeze
  AGGREGATION_FUNCTIONS = [:max, :avg].freeze

  def initialize(interval_seconds=60)
    @interval_seconds = interval_seconds.to_i
    @redis            = Redis.new
    @storage_key      = "ez-metrics"
  end

  def log(payload={duration: 0.0, views: 0.0, db: 0.0, queries: 0, status: 200})
    @safe_payload = {
      duration: payload[:duration].to_f,
      views:    payload[:views].to_f,
      db:       payload[:db].to_f,
      queries:  payload[:queries].to_i,
      status:   payload[:status].to_i
    }

    this_second          = Time.now.to_i
    status_group         = "#{payload[:status].to_s[0]}xx"
    @this_second_metrics = redis.get("#{storage_key}:#{this_second}")

    if this_second_metrics
      @this_second_metrics = Oj.load(this_second_metrics)

      METRICS.each do |metrics_type|
        update_sum(metrics_type)
        update_max(metrics_type)
      end

      this_second_metrics["statuses"]["all"]        += 1
      this_second_metrics["statuses"][status_group] += 1
    else
      @this_second_metrics = {
        "duration_sum" => safe_payload[:duration],
        "duration_max" => safe_payload[:duration],
        "views_sum"    => safe_payload[:views],
        "views_max"    => safe_payload[:views],
        "db_sum"       => safe_payload[:db],
        "db_max"       => safe_payload[:db],
        "queries_sum"  => safe_payload[:queries],
        "queries_max"  => safe_payload[:queries],
        "statuses"     => { "2xx" => 0, "3xx" => 0, "4xx" => 0, "5xx" => 0, "all" => 1 }
      }

      this_second_metrics["statuses"][status_group] = 1
    end

    redis.setex("#{storage_key}:#{this_second}", interval_seconds, Oj.dump(this_second_metrics))
    true
  rescue => error
    formatted_error(error)
  end

  def show(options=nil)
    @options          = options || default_options
    interval_start    = Time.now.to_i - interval_seconds
    interval_keys     = (interval_start..Time.now.to_i).to_a.map { |second| "#{storage_key}:#{second}" }
    @interval_metrics = redis.mget(interval_keys).compact.map { |hash| Oj.load(hash) }

    return {} unless interval_metrics.any?

    @requests = interval_metrics.map { |hash| hash["statuses"]["all"] }.compact.sum
    build_result
  rescue
    {}
  end

  private

  attr_reader :redis, :interval_seconds, :interval_metrics, :requests,
    :storage_key, :safe_payload, :this_second_metrics, :options

  def build_result
    result = {}

    if options[:requests]
      result[:requests] = {
        all: requests,
        grouped: {
          "2xx" => count("2xx"),
          "3xx" => count("3xx"),
          "4xx" => count("4xx"),
          "5xx" => count("5xx")
        }
      }
    end

    options.each do |metrics, aggregation_functions|
      next unless METRICS.include?(metrics)
      aggregation_functions = [aggregation_functions] unless aggregation_functions.is_a?(Array)
      next unless aggregation_functions.any?

      aggregation_functions.each do |aggregation_function|
        result[metrics] ||= {}
        result[metrics][aggregation_function] = aggregate(metrics, aggregation_function)
      end
    end
    result
  ensure
    result
  end

  def aggregate(metrics, aggregation_function)
    return unless AGGREGATION_FUNCTIONS.include?(aggregation_function)
    return avg("#{metrics}_sum".to_sym) if aggregation_function == :avg
    return max("#{metrics}_max".to_sym) if aggregation_function == :max
  end

  def update_sum(metrics)
    this_second_metrics["#{metrics}_sum"] += safe_payload[metrics.to_sym]
  end

  def update_max(metrics)
    max_value = [safe_payload[metrics.to_sym], this_second_metrics["#{metrics}_max"]].max
    this_second_metrics["#{metrics}_max"] = max_value
  end

  def avg(metrics)
    (interval_metrics.map { |h| h[metrics.to_s] }.sum.to_f / requests).round
  end

  def max(metrics)
    interval_metrics.map { |h| h[metrics.to_s] }.max.round
  end

  def count(group)
    interval_metrics.map { |h| h["statuses"][group.to_s] }.sum
  end

  def default_options
    {
      duration: AGGREGATION_FUNCTIONS,
      views:    AGGREGATION_FUNCTIONS,
      db:       AGGREGATION_FUNCTIONS,
      queries:  AGGREGATION_FUNCTIONS,
      requests: true
    }
  end

  def formatted_error(error)
    {
      error:     error.class.name,
      message:   error.message,
      backtrace: error.backtrace.reject { |line| line.match(/ruby|gems/) }
    }
  end
end

require "ezmetrics/benchmark"
