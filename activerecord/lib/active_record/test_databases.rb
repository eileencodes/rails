# frozen_string_literal: true

require "active_support/testing/parallelization"

module ActiveRecord
  module TestDatabases # :nodoc:
    ActiveSupport::Testing::Parallelization.after_fork_hook do |i|
      create_and_migrate(i, env_name: Rails.env)
    end

    ActiveSupport::Testing::Parallelization.run_cleanup_hook do |_|
      drop(env_name: Rails.env)
    end

    def self.create_and_migrate(i, env_name:)
      old, ENV["VERBOSE"] = ENV["VERBOSE"], "false"

      ActiveRecord::Base.configurations(legacy: false).configs_for(env_name) do |_, config|
        config["database"] += "-#{i}"
        ActiveRecord::Tasks::DatabaseTasks.create(config)
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Tasks::DatabaseTasks.migrate
      end
    ensure
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations(legacy: false).default_config(Rails.env))
      ENV["VERBOSE"] = old
    end

    def self.drop(env_name:)
      old, ENV["VERBOSE"] = ENV["VERBOSE"], "false"

      ActiveRecord::Base.configurations(legacy: false).configs_for(env_name) do |_, config|
        ActiveRecord::Tasks::DatabaseTasks.drop(config)
      end
    ensure
      ENV["VERBOSE"] = old
    end
  end
end
