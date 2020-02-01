module Dashboard
	class Ezmetrics < ::Rails::Engine
	  isolate_namespace Dashboard
	  config.autoload_paths += Dir["#{config.root}/lib/**/"]
	end
end
