Gem::Specification.new do |s|
  s.name          = "ezmetrics"
  s.version       = "0.0.2"
  s.date          = "2019-11-20"
  s.summary       = "EZmetrics"
  s.description   = "A simple tool for displaying live metrics for a Rails application"
  s.authors       = ["Nicolae Rotaru"]
  s.email         = "nyku.rn@gmail.com"
  s.homepage      = "https://github.com/nyku/ezmetrics"
  s.license       = "GPL-3.0"
  s.files         = ["lib/ezmetrics.rb"]
  s.require_paths = ["lib"]
  s.add_runtime_dependency "redis", ["~> 4.0"]
  s.add_development_dependency "redis", ["~> 4.0"]
end