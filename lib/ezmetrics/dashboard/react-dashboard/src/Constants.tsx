export const allMetricsList = [
  { value: "requests_all",           label: "requests: all" },
  { value: "requests_2xx",           label: "requests: 2xx" },
  { value: "requests_3xx",           label: "requests: 3xx" },
  { value: "requests_4xx",           label: "requests: 4xx" },
  { value: "requests_5xx",           label: "requests: 5xx" },

  { value: "duration_avg",           label: "duration: avg" },
  { value: "duration_max",           label: "duration: max" },
  { value: "duration_percentile_90", label: "duration: 90%" },
  { value: "duration_percentile_95", label: "duration: 95%" },
  { value: "duration_percentile_99", label: "duration: 99%" },

  { value: "views_avg",              label: "views: avg" },
  { value: "views_max",              label: "views: max" },
  { value: "views_percentile_90",    label: "views: 90%" },
  { value: "views_percentile_95",    label: "views: 95%" },
  { value: "views_percentile_99",    label: "views: 99%" },

  { value: "db_avg",                 label: "db: avg" },
  { value: "db_max",                 label: "db: max" },
  { value: "db_percentile_90",       label: "db: 90%" },
  { value: "db_percentile_95",       label: "db: 95%" },
  { value: "db_percentile_99",       label: "db: 99%" },

  { value: "queries_avg",            label: "queries: avg" },
  { value: "queries_max",            label: "queries: max" },
  { value: "queries_percentile_90",  label: "queries: 90%" },
  { value: "queries_percentile_95",  label: "queries: 95%" },
  { value: "queries_percentile_99",  label: "queries: 99%" }
]

export const allRefreshIntervals = [
  { label: "1 second",   value: 1000 },
  { label: "5 seconds",  value: 5000 },
  { label: "10 seconds", value: 10000 },
  { label: "30 seconds", value: 30000 },
  { label: "1 minute",   value: 60000 }
]

export const allTimeframes = [
  { label: "1 minute",   value: 60 },
  { label: "2 minutes",  value: 120 },
  { label: "30 minutes", value: 1800 },
  { label: "1 hour",     value: 3600 },
  { label: "3 hours",    value: 10800 },
  { label: "6 hours",    value: 21600 },
  { label: "12 hours",   value: 43200 },
  { label: "24 hours",   value: 86400 }
]

export const defaultOverviewMetrics = [
  { value: "requests_2xx", label: "requests: 2xx" },
  { value: "requests_3xx", label: "requests: 3xx" },
  { value: "requests_4xx", label: "requests: 4xx" },
  { value: "requests_5xx", label: "requests: 5xx" },
  { value: "duration_avg", label: "duration: avg" },
  { value: "duration_max", label: "duration: max" },
  { value: "views_avg",    label: "views: avg" },
  { value: "views_max",    label: "views: max" },
  { value: "db_avg",       label: "db: avg" },
  { value: "db_max",       label: "db: max" },
  { value: "queries_avg",  label: "queries: avg" },
  { value: "queries_max",  label: "queries: max" }
]

export const defaultGraphMetrics = [
  { value: "requests_all", label: "requests: all" },
  { value: "requests_5xx", label: "requests: 5xx" },
  { value: "duration_avg", label: "duration: avg" },
  { value: "duration_max", label: "duration: max" },
  { value: "db_avg",       label: "db: avg" },
  { value: "db_max",       label: "db: max" }
]