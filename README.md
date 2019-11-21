# ezmetrics
A simple tool for capturing and displaying Rails metrics.

## Installation

`gem 'ezmetrics'`

## Usage

1. Add `config/initializers/ezmetrics.rb` to your Rails application:

```ruby
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
    queries:  Thread.current[:queries].to_i,
    db:       event.payload[:db_runtime].to_f,
    duration: event.duration.to_f,
    status:   event.payload[:status].to_i || 500
  )
end
```

2. Display metrics

```ruby
EZmetrics.new.display
```

Will return a hash with the following structure:

```ruby
{
  duration: {
    avg: 5569,
    max: 9675
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

