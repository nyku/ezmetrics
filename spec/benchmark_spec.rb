require "spec_helper"

describe EZmetrics::Benchmark do
  describe "#measure_aggregation" do
    it "measures simple aggregation time" do
      EZmetrics::Benchmark.new.measure_aggregation
    end

    it "measures simple aggregation time (partitioned by minute)" do
      EZmetrics::Benchmark.new.measure_aggregation(:minute)
    end

    it "measures percentiles (db: percentile_90) aggregation time" do
      EZmetrics::Benchmark.new(true).measure_aggregation
    end

    it "measures percentiles (db: percentile_90) aggregation time (partitioned by minute)" do
      EZmetrics::Benchmark.new(true).measure_aggregation(:minute)
    end
  end
end
