# ezmetrics
A simple tool for displaying live metrics for a Rails application using Redis

## Install:

`gem "ezmetrics", git: "git@github.com:nyku/ezmetrics.git", ref: "master"`

Note: requires `redis` 4.0 or later

## Usage:

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

2. Run

```ruby
EZmetrics.new.display
```

\# =>

```ruby
{
  duration: {
    avg: 5569,
    max: 9675
  },
  db: {
    avg: 55,
    max: 82
  },
  queries: {
    avg: 26,
    max: 76
  },
  requests: {
    all: 7,
    grouped: {
      "2xx" => 3,
      "3xx" => 1,
      "4xx" => 1,
      "5xx" => 2
    }
  }
}
```

