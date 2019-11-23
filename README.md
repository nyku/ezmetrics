# ezmetrics

[![Gem Version](https://badge.fury.io/rb/ezmetrics.svg)](https://badge.fury.io/rb/ezmetrics)

A simple tool for capturing and displaying Rails metrics.


## Installation

```
gem 'ezmetrics'
```

## Usage

### Getting started

This tool captures and aggregates Rails application metrics such as
- `duration`
- `views`
- `db`
- `queries`
- `status`

and stores them for the timeframe you specified, 60 seconds by default.

You can change the timeframe according to your needs and save the metrics by calling `log` method:

```ruby
  # Store the metrics for 60 seconds (default behaviour)
  EZmetrics.new.log(duration: 100.5, views: 40.7, db: 59.8, queries: 4, status: 200)
```
or

```ruby
  # Store the metrics for 10 minutes
  EZmetrics.new(10.minutes).log(duration: 100.5, views: 40.7, db: 59.8, queries: 4, status: 200)
```

For displaying metrics you need call `show` method:

```ruby
  # Aggregate and show metrics for last 60 seconds (default behaviour)
  EZmetrics.new.show
```

or

```ruby
  # Aggregate and show metrics for last 10 minutes
  EZmetrics.new(10.minutes).show
```

> Please note that you can combine these timeframes, for example - store for 10 minutes, display for 5 minutes.


### Capture metrics

Just add an initializer to your application:

```ruby
# config/initializers/ezmetrics.rb

ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  unless event.payload[:name] == "SCHEMA"
    Thread.current[:queries] ||= 0
    Thread.current[:queries] += 1
  end
end

ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  EZmetrics.new.log(
    duration: event.duration.to_f,
    views:    event.payload[:view_runtime].to_f,
    db:       event.payload[:db_runtime].to_f,
    status:   event.payload[:status].to_i || 500,
    queries:  Thread.current[:queries].to_i,
  )
end
```

### Display metrics

As simple as:

```ruby
EZmetrics.new.show
```

This will return a hash with the following structure:

```ruby
{
  duration: {
    avg: 5569,
    max: 9675
  },
  views: {
    avg: 12,
    max: 240
  },
  db: {
    avg: 155,
    max: 4382
  },
  queries: {
    avg: 26,
    max: 76
  },
  requests: {
    all: 2000,
    grouped: {
      "2xx" => 1900,
      "3xx" => 15,
      "4xx" => 80,
      "5xx" => 5
    }
  }
}
```

### Performance

The implementation is based on **Redis** commands such as:  

- [`get`](https://redis.io/commands/get)  
- [`mget`](https://redis.io/commands/mget)
- [`setex`](https://redis.io/commands/setex)

which are extremely fast:

```bash
require 'ezmetrics'
require 'pp'
```

```ruby
pp Benchmark.measure {
  EZmetrics.new(1.hour).log(
    status:   rand(200..500), 
    duration: rand(10000), 
    views:    rand(8000), 
    db:       rand(6000), 
    queries:  rand(100)
  ) 
} ; nil

#<Benchmark::Tms:0x00007fc9cc995370
 @cstime=0.0,
 @cutime=0.0,
 @label="",
 @real=0.000742000003810972,
 @stime=0.00018599999999999173,
 @total=0.0005780000000001617,
 @utime=0.00039200000000017>
 => nil 

```

```ruby
pp Benchmark.measure {
  EZmetrics.new(1.hour).show 
} ; nil

#<Benchmark::Tms:0x00007fc9cca55508
 @cstime=0.0,
 @cutime=0.0,
 @label="",
 @real=0.025030000018887222,
 @stime=0.0018440000000000123,
 @total=0.023447000000000273,
 @utime=0.02160300000000026>
 => nil 
 ```
