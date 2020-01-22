# ezmetrics

[![Gem Version](https://badge.fury.io/rb/ezmetrics.svg)](https://badge.fury.io/rb/ezmetrics)

Simple, lightweight and fast metrics aggregation for Rails.

## Installation

```
gem 'ezmetrics'
```

## Available metrics

|    Type    |        Aggregate functions        |
| :--------: | :-------------------------------: |
| `duration` |    `avg`, `max`, `percentile`     |
|  `views`   |    `avg`, `max`, `percentile`     |
|    `db`    |    `avg`, `max`, `percentile`     |
| `queries`  |    `avg`, `max`, `percentile`     |
| `requests` | `all`, `2xx`, `3xx`, `4xx`, `5xx` |

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
EZmetrics.new.log(
  duration: 100.5,
  views:    40.7,
  db:       59.8,
  queries:  4,
  status:   200
)
```

```ruby
# Store the metrics for 10 minutes
EZmetrics.new(10.minutes).log(
  duration: 100.5,
  views:    40.7,
  db:       59.8,
  queries:  4,
  status:   200
)
```

---

For displaying metrics you need to call `show` method:

```ruby
# Aggregate and show metrics for last 60 seconds (default behaviour)
EZmetrics.new.show
```

```ruby
# Aggregate and show metrics for last 10 minutes
EZmetrics.new(10.minutes).show
```

You can combine these timeframes, for example - store for 10 minutes, display for 5 minutes.

### Capture metrics

Just add an initializer to your application:

```ruby
# config/initializers/ezmetrics.rb

ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  unless event.payload[:name] == "SCHEMA" || event.payload[:sql] =~ /\ABEGIN|COMMIT|ROLLBACK\z/
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
  Thread.current[:queries] = 0
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

---

If you prefer a single level object - you can change the default output structure by calling `.flatten` before `.show`

```ruby
EZmetrics.new(1.hour).flatten.show(db: :avg, duration: [:avg, :max])
```

```ruby
{
  db_avg:       182,
  duration_avg: 205,
  duration_max: 5171
}
```

---

Same for [partitioned aggregation](#partitioning)

```ruby
EZmetrics.new(1.hour).partition_by(:minute).flatten.show(db: :avg, duration: [:avg, :max])
```

```ruby
[
  {
    timestamp:    1575242880,
    db_avg:       387,
    duration_avg: 477,
    duration_max: 8566
  },
  {
    timestamp:    1575242940,
    db_avg:       123,
    duration_avg: 234,
    duration_max: 3675
  }
]
```

### Aggregation

The aggregation can be easily configured by specifying aggregation options as in the following examples:

**1. Single**

```ruby
EZmetrics.new.show(duration: :max)
```

```ruby
{
  duration: {
    max: 9675
  }
}
```

---

**2. Multiple**

```ruby
EZmetrics.new.show(queries: [:max, :avg])
```

```ruby
{
  queries: {
    max: 76,
    avg: 26
  }
}
```

---

**3. Requests**

```ruby
EZmetrics.new.show(requests: true)
```

```ruby
{
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

---

**4. Combined**

```ruby
EZmetrics.new.show(views: :avg, :db: [:avg, :max], requests: true)
```

```ruby
{
  views: {
    avg: 12
  },
  db: {
    avg: 155,
    max: 4382
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

---

**5. Percentile**

This feature is available since version `2.0.0`.

By default percentile aggregation is turned off because it requires to store each value of all metrics.

To enable this feature - you need to set `store_each_value: true` when saving the metrics:

```ruby
EZmetrics.new.log(
  duration:         100.5,
  views:            40.7,
  db:               59.8,
  queries:          4,
  status:           200,
  store_each_value: true
)
```

The aggregation syntax has the following format `metrics_type: :percentile_{number}` where `number` is any integer in the 1..99 range.

```ruby
EZmetrics.new.show(db: [:avg, :percentile_90, :percentile_95], duration: :percentile_99)
```

```ruby
{
  db: {
    avg: 155,
    percentile_90: 205,
    percentile_95: 215
  },
  duration: {
    percentile_99: 236
  }
}
```

**6. Percentile distribution**

If you want to visualize percentile distribution (from 1% to 99%):

```ruby
EZmetrics.new.show(duration: :percentile_distribution)
```

```ruby
{
  duration: {
    percentile_distribution: {
      1: 12,
      2: 15,
      3: 19,
      #...
      97: 6540,
      98: 6682,
      99: 6730
    }
  }
}
```

### Partitioning

If you want to visualize your metrics by using a **line chart**, you will need to use partitioning.

To aggregate metrics, partitioned by a unit of time you need to call `.partition_by({time_unit})` before calling `.show`

```ruby
# Aggregate metrics for last hour, partition by minute
EZmetrics.new(1.hour).partition_by(:minute).show(duration: [:avg, :max], db: :avg)
```

This will return an array of objects with the following structure:

```ruby
[
  {
    timestamp: # UNIX timestamp
    data:      # a hash with aggregated metrics
  }
]
```

like in the example below:

```ruby
[
  {
    timestamp: 1575242880,
    data: {
      duration: {
        avg: 477,
        max: 8566
      },
      db: {
        avg: 387
      }
    }
  },
  {
    timestamp: 1575242940,
    data: {
      duration: {
        avg: 234,
        max: 3675
      },
      db: {
        avg: 123
      }
    }
  }
]
```

Available time units for partitioning: `second`, `minute`, `hour`, `day`. Default: `minute`.

### Performance

The aggregation speed relies on the performance of **Redis** (data storage) and **Oj** (json serialization/parsing).

You can check the **aggregation** time (in seconds) by running:

```ruby
# 1. Simple
EZmetrics::Benchmark.new.measure_aggregation

# 2. Partitioned
EZmetrics::Benchmark.new.measure_aggregation(:minute)

# 3. Percentile
EZmetrics::Benchmark.new(true).measure_aggregation

# 4. Percentile (partitioned)
EZmetrics::Benchmark.new(true).measure_aggregation(:minute)
```

| Interval | Simple aggregation | Partitioned | Percentile | Percentile (partitioned) |
| :------: | :----------------: | :---------: | :--------: | :----------------------: |
| 1 minute |        0.0         |     0.0     |    0.0     |           0.0            |
|  1 hour  |        0.02        |    0.02     |    0.14    |           0.16           |
| 12 hours |        0.22        |    0.25     |    2.11    |           1.97           |
| 24 hours |        0.61        |    0.78     |    5.85    |           5.85           |
| 48 hours |        1.42        |    1.75     |    14.1    |           13.9           |

The benchmarks above were run on a _2017 Macbook Pro 2.9 GHz Intel Core i7 with 16 GB of RAM_

### License

ezmetrics is released under the [MIT License](https://opensource.org/licenses/MIT).
