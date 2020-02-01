require "spec_helper"

describe Ezmetrics::Storage do
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

    it "should handle percentiles" do
      log_metrics_store_each_value!

      expect(
        subject.show(
          duration: :percentile_90,
          views:    [:percentile_95, :percentile_99]
        )
      ).to eq(
        {
          duration: { percentile_90: 174 },
          views:    { percentile_95: 183, percentile_99: 191 }
        }
      )
    end

    it "should handle percentiles distribution" do
      log_metrics_store_each_value!

      expect(
        subject.show(duration: :percentile_distribution)
      ).to eq(
        {
          duration: {
            percentile_distribution: {
              1=>1, 2=>3, 3=>5, 4=>7, 5=>9, 6=>11, 7=>13, 8=>15, 9=>17, 10=>18, 11=>20, 12=>22, 13=>24, 14=>26, 15=>28,
              16=>30, 17=>32, 18=>34, 19=>36, 20=>38, 21=>40, 22=>42, 23=>44, 24=>46, 25=>48, 26=>49, 27=>51, 28=>53,
              29=>55, 30=>57, 31=>59, 32=>61, 33=>63, 34=>65, 35=>67, 36=>69, 37=>71, 38=>73, 39=>75, 40=>77, 41=>79,
              42=>80, 43=>82, 44=>84, 45=>86, 46=>88, 47=>90, 48=>92, 49=>94, 50=>96, 51=>98, 52=>100, 53=>102, 54=>104,
              55=>106, 56=>108, 57=>110, 58=>112, 59=>113, 60=>115, 61=>117, 62=>119, 63=>121, 64=>123, 65=>125, 66=>127,
              67=>129, 68=>131, 69=>133, 70=>135, 71=>137, 72=>139, 73=>141, 74=>143, 75=>144, 76=>146, 77=>148, 78=>150,
              79=>152, 80=>154, 81=>156, 82=>158, 83=>160, 84=>162, 85=>164, 86=>166, 87=>168, 88=>170, 89=>172, 90=>174,
              91=>175, 92=>177, 93=>179, 94=>181, 95=>183, 96=>185, 97=>187, 98=>189, 99=>191
            }
          }
        }
      )
    end

    it "should handle percentiles with not enough data" do
      redis.flushdb

      values = Array.new(98) { |i| (i.to_f*1.9+1).round(2) }.shuffle

      values.each do |value|
        subject.log(duration: value, views: value, db: value, queries: 2, status: 200, store_each_value: true)
      end

      expect(
        subject.show(duration: [:percentile_90, :percentile_99])
      ).to eq(
        {
          duration: { percentile_90: 168, percentile_99: "not enough data (requests: 98, required: 99)" }
        }
      )
    end

    it "should display flat view" do
      expect(subject.flatten.show).to eq(
        {
          duration_avg: 56,
          duration_max: 100,
          views_avg:    29,
          views_max:    52,
          db_avg:       15,
          db_max:       26,
          queries_avg:  3,
          queries_max:  4,
          requests_all: 4,
          requests_2xx: 1,
          requests_3xx: 1,
          requests_4xx: 1,
          requests_5xx: 1
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
      expect(Ezmetrics::Storage.new.show).to eq(
        {
          duration: { avg: 101, max: 101 },
          views:    { avg: 71, max: 71 },
          db:       { avg: 24, max: 24 },
          queries:  { avg: 1, max: 1 },
          requests: { all: 1, grouped: { "2xx" => 1, "3xx" => 0, "4xx" => 0, "5xx" => 0 } }
        }
      )

      sleep(1)

      expect(Ezmetrics::Storage.new.show).to eq({})
    end

    it "should handle log/show errors" do
      expect(Redis).to receive(:new).and_return(nil).exactly(2).times
      log_result = Ezmetrics::Storage.new.log(views: 3.1, db: 12.5, duration: 10.4, status: 200)

      expect(log_result[:error]).to     eq("NoMethodError")
      expect(log_result[:message]).to   include("undefined method `get'")
      expect(log_result[:backtrace]).to be

      expect(Ezmetrics::Storage.new.show).to eq({})
    end
  end

  describe ".partition_by.show" do
    before do
      redis.flushdb
    end

    it "should return all metrics, partitioned by :second" do
      log_metrics!(1)

      expect(Ezmetrics::Storage.new.partition_by(:second).show).to eq(
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

      expect(Ezmetrics::Storage.new.partition_by(:minute).show).to eq(
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

      expect(Ezmetrics::Storage.new.partition_by(:hour).show).to eq(
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

    it "should display flat view" do
      log_metrics!(1)

      expect(Ezmetrics::Storage.new.flatten.partition_by(:hour).show).to eq(
        [
          {
            timestamp: Time.new(*Time.now.to_a[0..5].reverse[0..3]).to_i,
            duration_avg: 56,
            duration_max: 100,
            views_avg:    29,
            views_max:    52,
            db_avg:       15,
            db_max:       21,
            queries_avg:  3,
            queries_max:  4,
            requests_all: 4,
            requests_2xx: 1,
            requests_3xx: 1,
            requests_4xx: 1,
            requests_5xx: 1
          }
        ]
      )
    end
  end
end

def log_metrics_store_each_value!
  redis.flushdb

  values = Array.new(101) { |i| (i.to_f*1.9+1).round(2) }.shuffle

  values.each do |value|
    subject.log(duration: value, views: value, db: value, queries: 2, status: 200, store_each_value: true)
    sleep 0.02
  end
end

def log_metrics!(sleep_time=0)
  subject.log(duration: 10.4, views: 8, db: 12.5, queries: 2, status: 200)
  subject.log(duration: 12.4, views: 9.4, db: 25.8, queries: 3, status: 301)
  sleep sleep_time
  subject.log(duration: 100.4, views: 52.3, db: 20.8, queries: 1, status: 404)
  subject.log(duration: 100.4, views: 45, db: nil, queries: 4, status: 500)
end
