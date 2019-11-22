Gem::Specification.new do |gem|
  gem.name                  = "ezmetrics"
  gem.version               = "1.0.5"
  gem.date                  = "2019-11-22"
  gem.summary               = "Rails metrics aggregation tool."
  gem.description           = "A simple tool for capturing and displaying Rails metrics."
  gem.authors               = ["Nicolae Rotaru"]
  gem.email                 = "nyku.rn@gmail.com"
  gem.homepage              = "https://github.com/nyku/ezmetrics"
  gem.license               = "GPL-3.0"
  gem.files                 = ["lib/ezmetrics.rb", "LICENSE", "README.md"]
  gem.require_paths         = ["lib"]
  gem.required_ruby_version = ">= 2.4.0"
  gem.add_dependency "redis", ["~> 4.0"]
  gem.add_development_dependency "rspec", "~> 3.5"
end