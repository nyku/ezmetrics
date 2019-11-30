require "benchmark"

class EZmetrics::Benchmark

  def initialize
    @start               = Time.now.to_i
    @redis               = Redis.new
    @durations           = []
    @iterations          = 3
    @requests_per_second = 100
    @intervals           = {
      "1.minute" => 60,
      "1.hour  " => 3600,
      "12.hours" => 43200,
      "24.hours" => 86400,
      "48.hours" => 172800
    }
  end

  def measure_aggregation
    write_metrics
    print_header
    intervals.each do |interval, seconds|
      result = measure_aggregation_time(interval, seconds)
      print_row(result)
    end
    cleanup_metrics
    print_footer
  end

  private

  attr_reader :start, :redis, :durations, :intervals, :iterations, :requests_per_second

  def write_metrics
    seconds = intervals.values.max
    seconds.times do |i|
      second = start - i
      payload = {
        "duration_sum"    => rand(10000),
        "duration_max"    => rand(10000),
        "views_sum"       => rand(1000),
        "views_max"       => rand(1000),
        "db_sum"          => rand(8000),
        "db_max"          => rand(8000),
        "queries_sum"     => rand(100),
        "queries_max"     => rand(100),
        "statuses"        => {
          "2xx" => rand(10),
          "3xx" => rand(10),
          "4xx" => rand(10),
          "5xx" => rand(10),
          "all" => rand(40)
        }
      }
      redis.setex("ez-metrics:#{second}", seconds, Oj.dump(payload))
    end
    nil
  end

  def cleanup_metrics
    interval_start = Time.now.to_i - intervals.values.max - 100
    interval_keys  = (interval_start..Time.now.to_i).to_a.map { |second| "ez-metrics:#{second}" }
    redis.del(interval_keys)
  end

  def measure_aggregation_time(interval, seconds)
    iterations.times do
      durations << ::Benchmark.measure { EZmetrics.new(seconds).show }.real
    end

    return {
      interval: interval.gsub(".", " "),
      duration: (durations.sum.to_f / iterations).round(2)
    }
  end

  def print_header
    print "\n#{'─'*31}\n| Interval | Duration (seconds)\n#{'─'*31}\n"
  end

  def print_row(result)
    print "| #{result[:interval]} | #{result[:duration]}\n"
  end

  def print_footer
    print "#{'─'*31}\n"
  end
end
