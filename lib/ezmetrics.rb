require "redis" unless defined?(Redis)

class EZmetrics
  attr_reader :redis, :last_minute_metrics, :requests, :redis_key

  def initialize
    @redis = Redis.new
    @redis_key = "ez-metrics"
  end

  def log(payload)
    payload = {
      db:       payload[:db].to_f,
      queries:  payload[:queries].to_i,
      duration: payload[:duration].to_f,
      status:   payload[:status].to_i
    }

    current_second      = Time.now.sec
    status_group        = "#{payload[:status].to_s[0]}xx"
    this_second_metrics = redis.get("#{redis_key}:#{current_second}")

    if this_second_metrics
      this_second_metrics = JSON.parse(this_second_metrics)
      this_second_metrics["db_sum"]                 += payload[:db]
      this_second_metrics["queries_sum"]            += payload[:queries]
      this_second_metrics["duration_sum"]           += payload[:duration]
      this_second_metrics["statuses"]["all"]        += 1
      this_second_metrics["statuses"][status_group] += 1
      this_second_metrics["db_max"]                 = [payload[:db], this_second_metrics["db_max"]].max
      this_second_metrics["queries_max"]            = [payload[:queries], this_second_metrics["queries_max"]].max
      this_second_metrics["duration_max"]           = [payload[:duration], this_second_metrics["duration_max"]].max
    else
      this_second_metrics = {
        "db_sum"       => payload[:db],
        "db_max"       => payload[:db],
        "queries_sum"  => payload[:queries],
        "queries_max"  => payload[:queries],
        "duration_sum" => payload[:duration],
        "duration_max" => payload[:duration],
        "statuses"     => { "2xx" => 0, "3xx" => 0, "4xx" => 0, "5xx" => 0, "all" => 1 }
      }

      this_second_metrics["statuses"][status_group] = 1
    end

    redis.setex("#{redis_key}:#{current_second}", 59, this_second_metrics.to_json)
  rescue => error
    display_error(error)
  end

  def show
    @last_minute_metrics = redis.mget((0..59).to_a.map { |second| "#{redis_key}:#{second}" }).compact.map { |m| JSON.parse(m) }

    return empty_metrics unless last_minute_metrics.any?

    @requests = last_minute_metrics.map { |h| h["statuses"]["all"] }.compact.sum

    {
      duration: {
        avg: avg(:duration_sum),
        max: max(:duration_max)
      },
      db: {
        avg: avg(:db_sum),
        max: max(:db_max)
      },
      queries: {
        avg: avg(:queries_sum),
        max: max(:queries_max)
      },
      requests:     {
        all:     requests,
        grouped: {
          "2xx" => count("2xx"),
          "3xx" => count("3xx"),
          "4xx" => count("4xx"),
          "5xx" => count("5xx")
        }
      }
    }
  rescue
    empty_metrics
  end

  private

  def avg(metrics)
    (last_minute_metrics.map { |h| h[metrics.to_s] }.sum.to_f / requests).round
  end

  def max(metrics)
    last_minute_metrics.map { |h| h[metrics.to_s] }.max.round
  end

  def count(group)
    last_minute_metrics.map { |h| h["statuses"][group.to_s] }.sum
  end

  def display_error(error)
    {
      error:     error.class.name,
      message:   error.message,
      backtrace: error.backtrace.reject { |line| line.match(/ruby|gems/) }
    }
  end

  def empty_metrics
    {
      duration: {
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