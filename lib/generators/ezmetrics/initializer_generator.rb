require 'rails/generators/base'

module Ezmetrics
  module Generators
    class InitializerGenerator < Rails::Generators::Base
      desc "This generator creates an initializer file at config/initializers"

      def create_initializer_file
        create_file "config/initializers/ezmetrics.rb", config_content
      end

      def config_content
<<RUBY
ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  unless event.payload[:name] == "SCHEMA" || event.payload[:sql] =~ /\ABEGIN|COMMIT|ROLLBACK\z/
    Thread.current[:queries] ||= 0
    Thread.current[:queries] += 1
  end
end

ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Ezmetrics::Storage.new(24.hours).log(
    duration: event.duration.to_f,
    views:    event.payload[:view_runtime].to_f,
    db:       event.payload[:db_runtime].to_f,
    status:   event.payload[:exception] ? 500 : event.payload[:status].to_i,
    queries:  Thread.current[:queries].to_i,
    store_each_value: true
  )

  Thread.current[:queries] = 0
end
RUBY
      end
    end
  end
end