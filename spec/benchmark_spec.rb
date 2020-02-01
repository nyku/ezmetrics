require "spec_helper"

describe Ezmetrics::Benchmark do
  describe "#measure_aggregation" do
    it "measures simple aggregation time" do
      Ezmetrics::Benchmark.new.measure_aggregation
    end

    it "measures simple aggregation time (partitioned by minute)" do
      Ezmetrics::Benchmark.new.measure_aggregation(:minute)
    end

    it "measures percentiles (db: percentile_90) aggregation time" do
      Ezmetrics::Benchmark.new(true).measure_aggregation
    end

    it "measures percentiles (db: percentile_90) aggregation time (partitioned by minute)" do
      Ezmetrics::Benchmark.new(true).measure_aggregation(:minute)
    end
  end
end
