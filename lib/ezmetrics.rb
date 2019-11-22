require "redis" unless defined?(Redis)
require "json"  unless defined?(JSON)

class EZmetrics
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
      @this_second_metrics = JSON.parse(this_second_metrics)

      [:duration, :views, :db, :queries].each do |metrics_type|
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

    redis.setex("#{storage_key}:#{this_second}", interval_seconds, JSON.generate(this_second_metrics))

    true
  rescue => error
    formatted_error(error)
  end

  def show
    interval_start    = Time.now.to_i - interval_seconds
    interval_keys     = (interval_start..Time.now.to_i).to_a.map { |second| "#{storage_key}:#{second}" }
    @interval_metrics = redis.mget(interval_keys).compact.map { |hash| JSON.parse(hash) }

    return empty_metrics_object unless interval_metrics.any?

    @requests = interval_metrics.map { |hash| hash["statuses"]["all"] }.compact.sum

    metrics_object
  rescue
    empty_metrics_object
  end

  private

  attr_reader :redis, :interval_seconds, :interval_metrics, :requests, :storage_key,
    :safe_payload, :this_second_metrics

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

  def formatted_error(error)
    {
      error:     error.class.name,
      message:   error.message,
      backtrace: error.backtrace.reject { |line| line.match(/ruby|gems/) }
    }
  end

  def metrics_object
    {
      duration: {
        avg: avg(:duration_sum),
        max: max(:duration_max)
      },
      views: {
        avg: avg(:views_sum),
        max: max(:views_max)
      },
      db: {
        avg: avg(:db_sum),
        max: max(:db_max)
      },
      queries: {
        avg: avg(:queries_sum),
        max: max(:queries_max)
      },
      requests: {
        all:     requests,
        grouped: {
          "2xx" => count("2xx"),
          "3xx" => count("3xx"),
          "4xx" => count("4xx"),
          "5xx" => count("5xx")
        }
      }
    }
  end

  def empty_metrics_object
    {
      duration: {
        avg: 0,
        max: 0
      },
      views: {
        avg: 0,
        max: 0
      },
      db: {
        avg: 0,
        max: 0
      },
      queries: {
        avg: 0,
        max: 0
      },
      requests: {}
    }
  end
end