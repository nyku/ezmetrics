require "redis" unless defined?(Redis)

class EZmetrics
  REDIS_KEY = "ez-metrics"

  def self.log(payload)
    payload = {
      db:       payload[:db].to_f,
      queries:  payload[:queries].to_i,
      duration: payload[:duration].to_f,
      status:   payload[:status].to_i
    }

    redis               = Redis.new
    current_second      = Time.now.sec
    status_group        = "#{payload[:status].to_s[0]}xx"
    this_second_metrics = redis.get("#{REDIS_KEY}:#{current_second}")

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

    redis.setex("#{REDIS_KEY}:#{current_second}", 59, this_second_metrics.to_json)
  rescue
    nil
  end

  def self.show
    redis         = Redis.new
    empty_metrics = {
      avg_db:       0,
      avg_duration: 0,
      avg_queries:  0,
      max_db:       0,
      max_duration: 0,
      max_queries:  0,
      statuses:     {}
    }

    last_minute_metrics = redis.mget((0..59).to_a.map { |second| "#{REDIS_KEY}:#{second}" }).compact.map { |m| JSON.parse(m) }

    return empty_metrics unless last_minute_metrics.any?

    requests = last_minute_metrics.map { |h| h["statuses"]["all"] }.compact.sum

    {
      avg_db:       (last_minute_metrics.map { |h| h["db_sum"] }.sum.to_f / requests).round,
      avg_duration: (last_minute_metrics.map { |h| h["duration_sum"] }.sum.to_f / requests).round,
      avg_queries:  (last_minute_metrics.map { |h| h["queries_sum"] }.sum.to_f / requests).round,
      max_db:       last_minute_metrics.map { |h| h["db_max"] }.max.round,
      max_queries:  last_minute_metrics.map { |h| h["queries_max"] }.max.round,
      max_duration: last_minute_metrics.map { |h| h["duration_max"] }.max.round,
      statuses:     {
        all:     requests,
        grouped: {
          "2xx" => last_minute_metrics.map { |h| h["statuses"]["2xx"] }.sum,
          "3xx" => last_minute_metrics.map { |h| h["statuses"]["3xx"] }.sum,
          "4xx" => last_minute_metrics.map { |h| h["statuses"]["4xx"] }.sum,
          "5xx" => last_minute_metrics.map { |h| h["statuses"]["5xx"] }.sum
        }
      }
    }
  rescue
    empty_metrics
  end
end
