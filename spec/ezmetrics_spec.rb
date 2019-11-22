require "spec_helper"

describe EZmetrics do
  let(:redis) { Redis.current }

  before do
    Redis.new.flushdb
  end

  describe "log/show" do
    it "should log metrics to redis and aggregate them" do
      subject.log(duration: 10.4, views: 8, db: 12.5, queries: 2, status: 200)
      expect(subject.show).to eq(
        {
          duration: {
            avg: 10,
            max: 10
          },
          views: {
            avg: 8,
            max: 8
          },
          db: {
            avg: 13,
            max: 13
          },
          queries: {
            avg: 2,
            max: 2
          },
          requests: {
            all: 1,
            grouped: {
              "2xx" => 1,
              "3xx" => 0,
              "4xx" => 0,
              "5xx" => 0
            }
          }
        }
      )

      puts subject.log(duration: 12.4, views: 9.4, db: 25.8, queries: 3, status: 301)
      expect(subject.show).to eq(
        {
          duration: {
            avg: 11,
            max: 12
          },
          views: {
            avg: 9,
            max: 9
          },
          db: {
            avg: 19,
            max: 26
          },
          queries: {
            avg: 3,
            max: 3
          },
          requests: {
            all: 2,
            grouped: {
              "2xx" => 1,
              "3xx" => 1,
              "4xx" => 0,
              "5xx" => 0
            }
          }
        }
      )

      subject.log(duration: 100.4, views: 52.3, db: 20.8, queries: 1, status: 404)

      expect(subject.show).to eq(
        {
          duration: {
            avg: 41,
            max: 100
          },
          views: {
            avg: 23,
            max: 52
          },
          db: {
            avg: 20,
            max: 26
          },
          queries: {
            avg: 2,
            max: 3
          },
          requests: {
            all: 3,
            grouped: {
              "2xx" => 1,
              "3xx" => 1,
              "4xx" => 1,
              "5xx" => 0
            }
          }
        }
      )

      subject.log(duration: 100.4, views: 45, db: nil, queries: 4, status: 500)

      expect(subject.show).to eq(
        {
          duration: {
            avg: 56,
            max: 100
          },
          views: {
            avg: 29,
            max: 52
          },
          db: {
            avg: 15,
            max: 26
          },
          queries: {
            avg: 3,
            max: 4
          },
          requests: {
            all: 4,
            grouped: {
              "2xx" => 1,
              "3xx" => 1,
              "4xx" => 1,
              "5xx" => 1
            }
          }
        }
      )
    end

    it "should expire stored keys" do
      described_class.new(1).log(duration: 100.5, views: 71.4, db: 24.4, queries: 1, status: 200)
      expect(subject.show).to eq(
        {
          duration: {
            avg: 101,
            max: 101
          },
          views: {
            avg: 71,
            max: 71
          },
          db: {
            avg: 24,
            max: 24
          },
          queries: {
            avg: 1,
            max: 1
          },
          requests: {
            all: 1,
            grouped: {
              "2xx" => 1,
              "3xx" => 0,
              "4xx" => 0,
              "5xx" => 0
            }
          }
        }
      )

      sleep(1)

      expect(subject.show).to eq({
        duration: { avg: 0, max: 0 },
        views:    { avg: 0, max: 0 },
        db:       { avg: 0, max: 0 },
        queries:  { avg: 0, max: 0 },
        requests: {}
      })
    end

    it "should handle log/show errors" do
      expect(Redis).to  receive(:new).and_return(nil)

      log_result = subject.log(views: 3.1, db: 12.5, duration: 10.4, status: 200)

      expect(log_result[:error]).to     eq("NoMethodError")
      expect(log_result[:message]).to   include("undefined method `get'")
      expect(log_result[:backtrace]).to be

      expect(subject.show).to eq({
        duration: { avg: 0, max: 0 },
        views:    { avg: 0, max: 0 },
        db:       { avg: 0, max: 0 },
        queries:  { avg: 0, max: 0 },
        requests: {}
      })
    end
  end
end