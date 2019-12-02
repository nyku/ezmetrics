require "spec_helper"

describe EZmetrics do
  let(:redis) { Redis.new }

  before do
    redis.flushdb
    log_metrics!
  end

  describe "log/show" do
    it "should log metrics to redis and aggregate them (default options)" do
      expect(subject.show).to eq(
        {
          duration: { avg: 56, max: 100 },
          views:    { avg: 29, max: 52 },
          db:       { avg: 15, max: 26 },
          queries:  { avg: 3, max: 4 },
          requests: { all: 4, grouped: { "2xx" => 1, "3xx" => 1, "4xx" => 1, "5xx" => 1 } }
        }
      )
    end

    it "should perform partial aggregation (wrong options)" do
      expect(subject.show(wrong: :key)).to eq({})
    end

    context "when partial aggregation is invoked" do
      it "handles single option" do
        expect(subject.show(views: :avg)).to eq({ views: { avg: 29 } })
      end

      it "handles combined options" do
        expect(subject.show(duration: [:avg, :max], queries: :max)).to eq(
          {
            duration: { avg: 56, max: 100 },
            queries:  { max: 4 }
          }
        )
      end

      it "handles requests" do
        expect(subject.show(requests: true)).to eq(
          {
            requests: { all: 4, grouped: { "2xx" => 1, "3xx" => 1, "4xx" => 1, "5xx" => 1 } }
          }
        )
      end
    end

    it "should expire stored keys" do
      redis.flushdb
      described_class.new(1).log(duration: 100.5, views: 71.4, db: 24.4, queries: 1, status: 200)
      expect(EZmetrics.new.show).to eq(
        {
          duration: { avg: 101, max: 101 },
          views:    { avg: 71, max: 71 },
          db:       { avg: 24, max: 24 },
          queries:  { avg: 1, max: 1 },
          requests: { all: 1, grouped: { "2xx" => 1, "3xx" => 0, "4xx" => 0, "5xx" => 0 } }
        }
      )

      sleep(1)

      expect(EZmetrics.new.show).to eq({})
    end

    it "should handle log/show errors" do
      expect(Redis).to receive(:new).and_return(nil).exactly(2).times
      log_result = EZmetrics.new.log(views: 3.1, db: 12.5, duration: 10.4, status: 200)

      expect(log_result[:error]).to     eq("NoMethodError")
      expect(log_result[:message]).to   include("undefined method `get'")
      expect(log_result[:backtrace]).to be

      expect(EZmetrics.new.show).to eq({})
    end
  end

  describe ".partition_by.show" do
    before do
      redis.flushdb
    end

    it "should return all metrics, partitioned by :second" do
      log_metrics!(1)

      expect(EZmetrics.new.partition_by(:second).show).to eq(
        [
          {
            timestamp: Time.now.to_i - 1,
            data: {
              requests: { all: 2, grouped: { "2xx" => 1, "3xx" => 1, "4xx" => 0, "5xx" => 0 } },
              duration: { max: 12, avg: 11 },
              views:    { max: 9, avg: 9 },
              db:       { max: 26, avg: 19 },
              queries:  { max: 3, avg: 3 }
            }
          },
          {
            timestamp: Time.now.to_i,
            data: {
              requests: { all: 2, grouped: { "2xx" => 0, "3xx" => 0, "4xx" => 1, "5xx" => 1 } },
              duration: { max: 100, avg: 100 },
              views:    { max: 52, avg: 49 },
              db:       { max: 21, avg: 10 },
              queries:  { max: 4, avg: 3 }
            }
          }
        ]
      )
    end

    it "should return all metrics, partitioned by :minute" do
      log_metrics!(1)

      expect(EZmetrics.new.partition_by(:minute).show).to eq(
        [
          {
            timestamp: Time.new(*Time.now.to_a[0..5].reverse[0..4]).to_i,
            data: {
              requests: { all: 4, grouped: { "2xx" => 1, "3xx" => 1, "4xx" => 1, "5xx" => 1 } },
              duration: { max: 100, avg: 56 },
              views:    { max: 52, avg: 29 },
              db:       { max: 21, avg: 15 },
              queries:  { max: 4, avg: 3 }
            }
          }
        ]
      )
    end

    it "should return all metrics, partitioned by :hour" do
      log_metrics!(1)

      expect(EZmetrics.new.partition_by(:hour).show).to eq(
        [
          {
            timestamp: Time.new(*Time.now.to_a[0..5].reverse[0..3]).to_i,
            data: {
              requests: { all: 4, grouped: { "2xx" => 1, "3xx" => 1, "4xx" => 1, "5xx" => 1 } },
              duration: { max: 100, avg: 56 },
              views:    { max: 52, avg: 29 },
              db:       { max: 21, avg: 15 },
              queries:  { max: 4, avg: 3 }
            }
          }
        ]
      )
    end
  end
end

def log_metrics!(sleep_time=0)
  subject.log(duration: 10.4, views: 8, db: 12.5, queries: 2, status: 200)
  subject.log(duration: 12.4, views: 9.4, db: 25.8, queries: 3, status: 301)
  sleep sleep_time
  subject.log(duration: 100.4, views: 52.3, db: 20.8, queries: 1, status: 404)
  subject.log(duration: 100.4, views: 45, db: nil, queries: 4, status: 500)
end
