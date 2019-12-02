require "spec_helper"

describe EZmetrics::Benchmark do
  describe "#measure_aggregation" do
    it "measures aggregation time" do
      EZmetrics::Benchmark.new.measure_aggregation
    end

    it "measures aggregation time (partitioned by :minute)" do
      EZmetrics::Benchmark.new.measure_aggregation(:minute)
    end
  end
end
