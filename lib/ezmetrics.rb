require "redis"
require "redis/connection/hiredis"
require "oj"

class EZmetrics
  METRICS               = [:duration, :views, :db, :queries].freeze
  AGGREGATION_FUNCTIONS = [:max, :avg].freeze
  PARTITION_UNITS       = [:second, :minute, :hour, :day].freeze

  def initialize(interval_seconds=60)
    @interval_seconds = interval_seconds.to_i
    @redis            = Redis.new
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
    @this_second_metrics = redis.get(this_second)

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
        "second"       => this_second,
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

    redis.setex(this_second, interval_seconds, Oj.dump(this_second_metrics))
    true
  rescue => error
    formatted_error(error)
  end

  def show(options=nil)
    @options = options || default_options
    partitioned_metrics ? aggregate_partitioned_data : aggregate_data
  end

  def flatten
    @flat = true
    self
  end

  def partition_by(time_unit=:minute)
    time_unit = PARTITION_UNITS.include?(time_unit) ? time_unit : :minute
    @partitioned_metrics = interval_metrics.group_by { |h| second_to_partition_unit(time_unit, h["second"]) }
    self
  end

  private

  attr_reader :redis, :interval_seconds, :interval_metrics, :requests, :flat,
    :storage_key, :safe_payload, :this_second_metrics, :partitioned_metrics, :options

  def aggregate_data
    return {} unless interval_metrics.any?
    @requests = interval_metrics.sum { |hash| hash["statuses"]["all"] }
    build_result
  rescue
    {}
  end

  def aggregate_partitioned_data
    partitioned_metrics.map do |partition, metrics|
      @interval_metrics = metrics
      @requests = interval_metrics.sum { |hash| hash["statuses"]["all"] }
      flat ? { timestamp: partition, **build_result } : { timestamp: partition, data: build_result }
    end
  rescue
    new(options)
  end

  def build_result
    result = {}

    if options[:requests]
      append_requests_to_result(result, { all: requests, grouped: count_all_status_groups })
    end

    options.each do |metrics, aggregation_functions|
      next unless METRICS.include?(metrics)
      aggregation_functions = [aggregation_functions] unless aggregation_functions.is_a?(Array)
      next unless aggregation_functions.any?

      aggregation_functions.each do |aggregation_function|
        aggregated_metrics = aggregate(metrics, aggregation_function)
        append_metrics_to_result(result, metrics, aggregation_function, aggregated_metrics)
      end
    end
    result
  ensure
    result
  end

  def append_requests_to_result(result, aggregated_requests)
    return result[:requests] = aggregated_requests unless flat

    result[:requests_all] = aggregated_requests[:all]
    aggregated_requests[:grouped].each do |group, counter|
      result[:"requests_#{group}"] = counter
    end
  end

  def append_metrics_to_result(result, metrics, aggregation_function, aggregated_metrics)
    return result[:"#{metrics}_#{aggregation_function}"] = aggregated_metrics if flat

    result[metrics] ||= {}
    result[metrics][aggregation_function] = aggregated_metrics
  end

  def second_to_partition_unit(time_unit, second)
    return second if time_unit == :second
    time = Time.at(second)
    return (time - time.sec - time.min * 60 - time.hour * 3600).to_i if time_unit == :day
    return (time - time.sec - time.min * 60).to_i                    if time_unit == :hour
    (time - time.sec).to_i
  end

  def interval_metrics
    @interval_metrics ||= begin
      interval_start    = Time.now.to_i - interval_seconds
      interval_keys     = (interval_start..Time.now.to_i).to_a
      redis.mget(interval_keys).compact.map { |hash| Oj.load(hash) }
    end
  end

  def aggregate(metrics, aggregation_function)
    return unless AGGREGATION_FUNCTIONS.include?(aggregation_function)
    return avg("#{metrics}_sum") if aggregation_function == :avg
    return max("#{metrics}_max") if aggregation_function == :max
  end

  def update_sum(metrics)
    this_second_metrics["#{metrics}_sum"] += safe_payload[metrics]
  end

  def update_max(metrics)
    max_value = [safe_payload[metrics], this_second_metrics["#{metrics}_max"]].max
    this_second_metrics["#{metrics}_max"] = max_value
  end

  def avg(metrics)
    (interval_metrics.sum { |h| h[metrics] }.to_f / requests).round
  end

  def max(metrics)
    interval_metrics.max { |h| h[metrics] }[metrics].round
  end

  def count_all_status_groups
    interval_metrics.inject({ "2xx" => 0, "3xx" => 0, "4xx" => 0, "5xx" => 0 }) do |result, h|
      result["2xx"] += h["statuses"]["2xx"]
      result["3xx"] += h["statuses"]["3xx"]
      result["4xx"] += h["statuses"]["4xx"]
      result["5xx"] += h["statuses"]["5xx"]
      result
    end
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
