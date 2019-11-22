# ezmetrics

[![Gem Version](https://badge.fury.io/rb/ezmetrics.svg)](https://badge.fury.io/rb/ezmetrics)

A simple tool for capturing and displaying Rails metrics.


## Installation

```
gem 'ezmetrics'
```

## Usage

### Getting started

This tool captures and aggregates metrics such as
- `duration`
- `views`
- `db`
- `queries`
- `status`

for a 60 seconds timeframe by default.

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


### Add an initializer to your Rails application

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

