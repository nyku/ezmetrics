require "spec_helper"

describe EZmetrics do
  let(:redis) { Redis.current }

  before do
    Redis.new.flushdb
  end

  describe "log/show" do
    it "should log metrics to redis and aggregate them" do
      subject.log(db: 12.5, duration: 10.4, status: 200)
      expect(subject.show).to eq(
        {
          db: {
            avg: 13,
            max: 13
          },
          duration: {
            avg: 10,
            max: 10
          },
          queries: {
            avg: 0,
            max: 0
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

      subject.log(db: 25.8, duration: 12.4, status: 301)
      expect(subject.show).to eq(
        {
          db: {
            avg: 19,
            max: 26
          },
          duration: {
            avg: 11,
            max: 12
          },
          queries: {
            avg: 0,
            max: 0
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

      subject.log(db: 20.8, duration: 10.4, status: 404)

      expect(subject.show).to eq(
        {
          db: {
            avg: 20,
            max: 26
          },
          duration: {
            avg: 11,
            max: 12
          },
          queries: {
            avg: 0,
            max: 0
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

      subject.log(db: nil, duration: 100.4, status: 500)

      expect(subject.show).to eq(
        {
          db: {
            avg: 15,
            max: 26
          },
          duration: {
            avg: 33,
            max: 100
          },
          queries: {
            avg: 0,
            max: 0
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

    it "should handle log/show errors" do
      expect(Redis).to  receive(:new).and_return(nil)

      log_result = subject.log(db: 12.5, duration: 10.4, status: 200)

      expect(log_result[:error]).to     eq("NoMethodError")
      expect(log_result[:message]).to   include("undefined method `get'")
      expect(log_result[:backtrace]).to be

      expect(subject.show).to eq({
        db:       { avg: 0, max: 0 },
        duration: { avg: 0, max: 0 },
        queries:  { avg: 0, max: 0 },
        requests: {}
      })
    end
  end
end