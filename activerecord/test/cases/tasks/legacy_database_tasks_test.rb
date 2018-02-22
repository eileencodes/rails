# frozen_string_literal: true

require "cases/helper"
require "active_record/tasks/database_tasks"

module ActiveRecord
  class LegacyDatabaseTasksCreateAllTest < ActiveRecord::TestCase
    def setup
      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end
      @configurations = { "development" => { "database" => "my-db" } }

      # To refrain from connecting to a newly created empty DB in sqlite3_mem tests
      ActiveRecord::Base.connection_handler.stubs(:establish_connection)
      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_ignores_configurations_without_databases
      @configurations["development"].merge!("database" => nil)

      assert_not_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
        ActiveRecord::Tasks::DatabaseTasks.create_all
      end
    end

    def test_ignores_remote_databases
      @configurations["development"].merge!("host" => "my.server.tld")
      $stderr.stubs(:puts).returns(nil)

      assert_not_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
        ActiveRecord::Tasks::DatabaseTasks.create_all
      end
    end

    def test_warning_for_remote_databases
      @configurations["development"].merge!("host" => "my.server.tld")

      assert_called_with($stderr, :puts, ["This task only modifies local databases. my-db is on a remote host."]) do
        ActiveRecord::Tasks::DatabaseTasks.create_all
      end
    end

    def test_creates_configurations_with_local_ip
      @configurations["development"].merge!("host" => "127.0.0.1")

      assert_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
        ActiveRecord::Tasks::DatabaseTasks.create_all
      end
    end

    def test_creates_configurations_with_local_host
      @configurations["development"].merge!("host" => "localhost")

      assert_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
        ActiveRecord::Tasks::DatabaseTasks.create_all
      end
    end

    def test_creates_configurations_with_blank_hosts
      @configurations["development"].merge!("host" => nil)

      assert_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
        ActiveRecord::Tasks::DatabaseTasks.create_all
      end
    end
  end

  class LegacyDatabaseTasksCreateCurrentTest < ActiveRecord::TestCase
    def setup
      @old_configurations = assert_deprecated do
        ActiveRecord::Base.configurations
      end
      @configurations = {
        "development" => { "database" => "dev-db" },
        "test"        => { "database" => "test-db" },
        "production"  => { "url" => "abstract://prod-db-url" }
      }

      ActiveRecord::Base.stubs(:establish_connection).returns(true)
      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_creates_current_environment_database
      assert_called_with(
        ActiveRecord::Tasks::DatabaseTasks,
        :create,
        ["database" => "test-db"],
      ) do
        ActiveRecord::Tasks::DatabaseTasks.create_current(
          ActiveSupport::StringInquirer.new("test")
        )
      end
    end

    def test_creates_current_environment_database_with_url
      assert_called_with(
        ActiveRecord::Tasks::DatabaseTasks,
        :create,
        ["adapter" => "abstract", "host" => "prod-db-url"],
      ) do
        ActiveRecord::Tasks::DatabaseTasks.create_current(
          ActiveSupport::StringInquirer.new("production")
        )
      end
    end

    def test_creates_test_and_development_databases_when_env_was_not_specified
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "test-db")

      ActiveRecord::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new("development")
      )
    end

    def test_creates_test_and_development_databases_when_rails_env_is_development
      old_env = ENV["RAILS_ENV"]
      ENV["RAILS_ENV"] = "development"
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "test-db")

      ActiveRecord::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new("development")
      )
    ensure
      ENV["RAILS_ENV"] = old_env
    end

    def test_establishes_connection_for_the_given_environments
      ActiveRecord::Tasks::DatabaseTasks.stubs(:create).returns true

      ActiveRecord::Base.expects(:establish_connection).with(:development)

      ActiveRecord::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new("development")
      )
    end
  end

  class LegacyDatabaseTasksCreateCurrentThreeTierTest < ActiveRecord::TestCase
    def setup
      @old_configurations = assert_deprecated do
        ActiveRecord::Base.configurations
      end
      @configurations = {
        "development" => { "primary" => { "database" => "dev-db" }, "secondary" => { "database" => "secondary-dev-db" } },
        "test" => { "primary" => { "database" => "test-db" }, "secondary" => { "database" => "secondary-test-db" } },
        "production" => { "primary" => { "url" => "abstract://prod-db-url" }, "secondary" => { "url" => "abstract://secondary-prod-db-url" } }
      }

      ActiveRecord::Base.stubs(:establish_connection).returns(true)
      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_creates_current_environment_database
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "test-db")

      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "secondary-test-db")

      ActiveRecord::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new("test")
      )
    end

    def test_creates_current_environment_database_with_url
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("adapter" => "abstract", "host" => "prod-db-url")

      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("adapter" => "abstract", "host" => "secondary-prod-db-url")

      ActiveRecord::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new("production")
      )
    end

    def test_creates_test_and_development_databases_when_env_was_not_specified
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "secondary-dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "test-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "secondary-test-db")

      ActiveRecord::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new("development")
      )
    end

    def test_creates_test_and_development_databases_when_rails_env_is_development
      old_env = ENV["RAILS_ENV"]
      ENV["RAILS_ENV"] = "development"
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "secondary-dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "test-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:create).
        with("database" => "secondary-test-db")

      ActiveRecord::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new("development")
      )
    ensure
      ENV["RAILS_ENV"] = old_env
    end

    def test_establishes_connection_for_the_given_environments_config
      ActiveRecord::Tasks::DatabaseTasks.stubs(:create).returns true

      ActiveRecord::Base.expects(:establish_connection).with(:development)

      ActiveRecord::Tasks::DatabaseTasks.create_current(
        ActiveSupport::StringInquirer.new("development")
      )
    end
  end

  class LegacyDatabaseTasksDropAllTest < ActiveRecord::TestCase
    def setup
      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end
      @configurations = { development: { "database" => "my-db" } }

      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_ignores_configurations_without_databases
      @configurations[:development].merge!("database" => nil)

      assert_not_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
        ActiveRecord::Tasks::DatabaseTasks.drop_all
      end
    end

    def test_ignores_remote_databases
      @configurations[:development].merge!("host" => "my.server.tld")
      $stderr.stubs(:puts).returns(nil)

      assert_not_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
        ActiveRecord::Tasks::DatabaseTasks.drop_all
      end
    end

    def test_warning_for_remote_databases
      @configurations[:development].merge!("host" => "my.server.tld")

      assert_called_with(
        $stderr,
        :puts,
        ["This task only modifies local databases. my-db is on a remote host."],
      ) do
        ActiveRecord::Tasks::DatabaseTasks.drop_all
      end
    end

    def test_drops_configurations_with_local_ip
      @configurations[:development].merge!("host" => "127.0.0.1")

      assert_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
        ActiveRecord::Tasks::DatabaseTasks.drop_all
      end
    end

    def test_drops_configurations_with_local_host
      @configurations[:development].merge!("host" => "localhost")

      assert_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
        ActiveRecord::Tasks::DatabaseTasks.drop_all
      end
    end

    def test_drops_configurations_with_blank_hosts
      @configurations[:development].merge!("host" => nil)

      assert_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
        ActiveRecord::Tasks::DatabaseTasks.drop_all
      end
    end
  end

  class LegacyDatabaseTasksDropCurrentTest < ActiveRecord::TestCase
    def setup
      @old_configurations = assert_deprecated do
        ActiveRecord::Base.configurations
      end
      @configurations = {
        "development" => { "database" => "dev-db" },
        "test"        => { "database" => "test-db" },
        "production"  => { "url" => "abstract://prod-db-url" }
      }

      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_drops_current_environment_database
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "test-db")

      ActiveRecord::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new("test")
      )
    end

    def test_drops_current_environment_database_with_url
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("adapter" => "abstract", "host" => "prod-db-url")

      ActiveRecord::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new("production")
      )
    end

    def test_drops_test_and_development_databases_when_env_was_not_specified
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "test-db")

      ActiveRecord::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new("development")
      )
    end

    def test_drops_testand_development_databases_when_rails_env_is_development
      old_env = ENV["RAILS_ENV"]
      ENV["RAILS_ENV"] = "development"
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "test-db")

      ActiveRecord::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new("development")
      )
    ensure
      ENV["RAILS_ENV"] = old_env
    end
  end

  class LegacyDatabaseTasksDropCurrentThreeTierTest < ActiveRecord::TestCase
    def setup
      @old_configurations = assert_deprecated do
        ActiveRecord::Base.configurations
      end
      @configurations = {
        "development" => { "primary" => { "database" => "dev-db" }, "secondary" => { "database" => "secondary-dev-db" } },
        "test" => { "primary" => { "database" => "test-db" }, "secondary" => { "database" => "secondary-test-db" } },
        "production" => { "primary" => { "url" => "abstract://prod-db-url" }, "secondary" => { "url" => "abstract://secondary-prod-db-url" } }
      }

      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_drops_current_environment_database
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "test-db")

      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "secondary-test-db")

      ActiveRecord::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new("test")
      )
    end

    def test_drops_current_environment_database_with_url
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("adapter" => "abstract", "host" => "prod-db-url")

      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("adapter" => "abstract", "host" => "secondary-prod-db-url")

      ActiveRecord::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new("production")
      )
    end

    def test_drops_test_and_development_databases_when_env_was_not_specified
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "secondary-dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "test-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "secondary-test-db")

      ActiveRecord::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new("development")
      )
    end

    def test_drops_testand_development_databases_when_rails_env_is_development
      old_env = ENV["RAILS_ENV"]
      ENV["RAILS_ENV"] = "development"
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "secondary-dev-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "test-db")
      ActiveRecord::Tasks::DatabaseTasks.expects(:drop).
        with("database" => "secondary-test-db")

      ActiveRecord::Tasks::DatabaseTasks.drop_current(
        ActiveSupport::StringInquirer.new("development")
      )
    ensure
      ENV["RAILS_ENV"] = old_env
    end
  end

  class LegacyDatabaseTasksPurgeCurrentTest < ActiveRecord::TestCase
    def test_purges_current_environment_database
      old_configurations = assert_deprecated do
        ActiveRecord::Base.configurations
      end
      configurations = {
        "development" => { "database" => "dev-db" },
        "test"        => { "database" => "test-db" },
        "production"  => { "database" => "prod-db" }
      }
      ActiveRecord::Base.configurations = configurations

      ActiveRecord::Tasks::DatabaseTasks.expects(:purge).
        with("database" => "prod-db")

      assert_called_with(ActiveRecord::Base, :establish_connection, [:production]) do
        ActiveRecord::Tasks::DatabaseTasks.purge_current("production")
      end
    ensure
      ActiveRecord::Base.configurations = old_configurations
    end
  end

  class LegacyDatabaseTasksPurgeAllTest < ActiveRecord::TestCase
    def test_purge_all_local_configurations
      old_configurations = assert_deprecated do
        ActiveRecord::Base.configurations
      end
      configurations = { development: { "database" => "my-db" } }
      ActiveRecord::Base.configurations = configurations

      ActiveRecord::Tasks::DatabaseTasks.expects(:purge).
        with("database" => "my-db")

      ActiveRecord::Tasks::DatabaseTasks.purge_all
    ensure
      ActiveRecord::Base.configurations = old_configurations
    end
  end
end
