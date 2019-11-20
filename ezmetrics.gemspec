Gem::Specification.new do |gem|
  gem.name          = "ezmetrics"
  gem.version       = "0.0.3"
  gem.date          = "2019-11-21"
  gem.summary       = "A simple tool for displaying live metrics for a Rails application uning Redis"
  gem.description   = "A simple tool for displaying live metrics for a Rails application uning Redis"
  gem.authors       = ["Nicolae Rotaru"]
  gem.email         = "nyku.rn@gmail.com"
  gem.homepage      = "https://github.com/nyku/ezmetrics"
  gem.license       = "GPL-3.0"
  gem.files         = ["lib/ezmetrics.rb"]
  gem.require_paths = ["lib"]

  gem.add_dependency "redis", ["~> 4.0"]
end