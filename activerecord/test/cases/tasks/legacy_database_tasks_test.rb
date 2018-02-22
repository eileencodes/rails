# frozen_string_literal: true

require "cases/helper"
require "active_record/tasks/database_tasks"

module ActiveRecord
  class LegacyDatabaseTasksCreateAllTest < ActiveRecord::TestCase
    def setup
      @old_config_setting = ActiveRecord::Base.use_legacy_configurations
      ActiveRecord::Base.use_legacy_configurations = true

      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end

      @configurations = { "development" => { "database" => "my-db" } }

      $stdout, @original_stdout = StringIO.new, $stdout
      $stderr, @original_stderr = StringIO.new, $stderr

      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      $stdout, $stderr = @original_stdout, @original_stderr
      ActiveRecord::Base.use_legacy_configurations = @old_config_setting
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_ignores_configurations_without_databases
      @configurations["development"]["database"] = nil

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_not_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
            ActiveRecord::Tasks::DatabaseTasks.create_all
          end
        end
      end
    end

    def test_ignores_remote_databases
      @configurations["development"]["host"] = "my.server.tld"

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_not_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
            ActiveRecord::Tasks::DatabaseTasks.create_all
          end
        end
      end
    end

    def test_warning_for_remote_databases
      @configurations["development"]["host"] = "my.server.tld"

      assert_deprecated do
        ActiveRecord::Base.configurations do
          ActiveRecord::Tasks::DatabaseTasks.create_all

          assert_match "This task only modifies local databases. my-db is on a remote host.",
            $stderr.string
        end
      end
    end

    def test_creates_configurations_with_local_ip
      @configurations["development"]["host"] = "127.0.0.1"

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
            ActiveRecord::Tasks::DatabaseTasks.create_all
          end
        end
      end
    end

    def test_creates_configurations_with_local_host
      @configurations["development"]["host"] = "localhost"

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
            ActiveRecord::Tasks::DatabaseTasks.create_all
          end
        end
      end
    end

    def test_creates_configurations_with_blank_hosts
      @configurations["development"]["host"] = nil

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called(ActiveRecord::Tasks::DatabaseTasks, :create) do
            ActiveRecord::Tasks::DatabaseTasks.create_all
          end
        end
      end
    end
  end

  class LegacyDatabaseTasksCreateCurrentTest < ActiveRecord::TestCase
    def setup
      @old_config_setting = ActiveRecord::Base.use_legacy_configurations
      ActiveRecord::Base.use_legacy_configurations = true

      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end

      @configurations = {
        "development" => { "database" => "dev-db" },
        "test"        => { "database" => "test-db" },
        "production"  => { "url" => "abstract://prod-db-url" }
      }

      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.use_legacy_configurations = @old_config_setting
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_creates_current_environment_database
      assert_deprecated do
        ActiveRecord::Base.configurations do
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
      end
    end

    def test_creates_current_environment_database_with_url
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :create,
            ["url" => "prod-db-url"],
          ) do
            ActiveRecord::Tasks::DatabaseTasks.create_current(
              ActiveSupport::StringInquirer.new("production")
            )
          end
        end
      end
    end

    def test_creates_test_and_development_databases_when_env_was_not_specified
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :create,
            [
              ["database" => "dev-db"],
              ["database" => "test-db"]
            ],
          ) do
            ActiveRecord::Tasks::DatabaseTasks.create_current(
              ActiveSupport::StringInquirer.new("development")
            )
          end
        end
      end
    end

    def test_creates_test_and_development_databases_when_rails_env_is_development
      old_env = ENV["RAILS_ENV"]
      ENV["RAILS_ENV"] = "development"

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :create,
            [
              ["database" => "dev-db"],
              ["database" => "test-db"]
            ],
          ) do
            ActiveRecord::Tasks::DatabaseTasks.create_current(
              ActiveSupport::StringInquirer.new("development")
            )
          end
        end
      end
    ensure
      ENV["RAILS_ENV"] = old_env
    end

    def test_establishes_connection_for_the_given_environments
      ActiveRecord::Tasks::DatabaseTasks.stub(:create, nil) do
        assert_called_with(ActiveRecord::Base, :establish_connection, [:development]) do
          ActiveRecord::Tasks::DatabaseTasks.create_current(
            ActiveSupport::StringInquirer.new("development")
          )
        end
      end
    end
  end

  class LegacyDatabaseTasksCreateCurrentThreeTierTest < ActiveRecord::TestCase
    def setup
      @old_config_setting = ActiveRecord::Base.use_legacy_configurations
      ActiveRecord::Base.use_legacy_configurations = true

      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end

      @configurations = {
        "development" => { "primary" => { "database" => "dev-db" }, "secondary" => { "database" => "secondary-dev-db" } },
        "test" => { "primary" => { "database" => "test-db" }, "secondary" => { "database" => "secondary-test-db" } },
        "production" => { "primary" => { "url" => "abstract://prod-db-url" }, "secondary" => { "url" => "abstract://secondary-prod-db-url" } }
      }

      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.use_legacy_configurations = @old_config_setting
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_creates_current_environment_database
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :create,
            [
              ["database" => "test-db"],
              ["database" => "secondary-test-db"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.create_current(
              ActiveSupport::StringInquirer.new("test")
            )
          end
        end
      end
    end

    def test_creates_current_environment_database_with_url
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :create,
            [
              ["url" => "prod-db-url"],
              ["url" => "secondary-prod-db-url"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.create_current(
              ActiveSupport::StringInquirer.new("production")
            )
          end
        end
      end
    end

    def test_creates_test_and_development_databases_when_env_was_not_specified
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :create,
            [
              ["database" => "dev-db"],
              ["database" => "secondary-dev-db"],
              ["database" => "test-db"],
              ["database" => "secondary-test-db"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.create_current(
              ActiveSupport::StringInquirer.new("development")
            )
          end
        end
      end
    end

    def test_creates_test_and_development_databases_when_rails_env_is_development
      old_env = ENV["RAILS_ENV"]
      ENV["RAILS_ENV"] = "development"

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :create,
            [
              ["database" => "dev-db"],
              ["database" => "secondary-dev-db"],
              ["database" => "test-db"],
              ["database" => "secondary-test-db"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.create_current(
              ActiveSupport::StringInquirer.new("development")
            )
          end
        end
      end
    ensure
      ENV["RAILS_ENV"] = old_env
    end

    def test_establishes_connection_for_the_given_environments_config
      ActiveRecord::Tasks::DatabaseTasks.stub(:create, nil) do
        assert_called_with(
          ActiveRecord::Base,
          :establish_connection,
          [:development]
        ) do
          ActiveRecord::Tasks::DatabaseTasks.create_current(
            ActiveSupport::StringInquirer.new("development")
          )
        end
      end
    end
  end

  class LegacyDatabaseTasksDropAllTest < ActiveRecord::TestCase
    def setup
      @old_config_setting = ActiveRecord::Base.use_legacy_configurations
      ActiveRecord::Base.use_legacy_configurations = true

      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end
      @configurations = { development: { "database" => "my-db" } }

      $stdout, @original_stdout = StringIO.new, $stdout
      $stderr, @original_stderr = StringIO.new, $stderr

      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      $stdout, $stderr = @original_stdout, @original_stderr
      ActiveRecord::Base.use_legacy_configurations = @old_config_setting
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_ignores_configurations_without_databases
      @configurations[:development]["database"] = nil

      ActiveRecord::Base.configurations do
        assert_not_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
          ActiveRecord::Tasks::DatabaseTasks.drop_all
        end
      end
    end

    def test_ignores_remote_databases
      @configurations[:development]["host"] = "my.server.tld"

      ActiveRecord::Base.configurations do
        assert_not_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
          ActiveRecord::Tasks::DatabaseTasks.drop_all
        end
      end
    end

    def test_warning_for_remote_databases
      @configurations[:development]["host"] = "my.server.tld"

      ActiveRecord::Base.configurations do
        ActiveRecord::Tasks::DatabaseTasks.drop_all

        assert_match "This task only modifies local databases. my-db is on a remote host.",
          $stderr.string
      end
    end

    def test_drops_configurations_with_local_ip
      @configurations[:development]["host"] = "127.0.0.1"

      ActiveRecord::Base.configurations do
        assert_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
          ActiveRecord::Tasks::DatabaseTasks.drop_all
        end
      end
    end

    def test_drops_configurations_with_local_host
      @configurations[:development]["host"] = "localhost"

      ActiveRecord::Base.configurations do
        assert_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
          ActiveRecord::Tasks::DatabaseTasks.drop_all
        end
      end
    end

    def test_drops_configurations_with_blank_hosts
      @configurations[:development]["host"] = nil

      ActiveRecord::Base.configurations do
        assert_called(ActiveRecord::Tasks::DatabaseTasks, :drop) do
          ActiveRecord::Tasks::DatabaseTasks.drop_all
        end
      end
    end
  end

  class LegacyDatabaseTasksDropCurrentTest < ActiveRecord::TestCase
    def setup
      @old_config_setting = ActiveRecord::Base.use_legacy_configurations
      ActiveRecord::Base.use_legacy_configurations = true

      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end

      @configurations = {
        "development" => { "database" => "dev-db" },
        "test"        => { "database" => "test-db" },
        "production"  => { "url" => "abstract://prod-db-url" }
      }

      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.use_legacy_configurations = @old_config_setting
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_drops_current_environment_database
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(ActiveRecord::Tasks::DatabaseTasks, :drop,
            ["database" => "test-db"]) do
            ActiveRecord::Tasks::DatabaseTasks.drop_current(
              ActiveSupport::StringInquirer.new("test")
            )
          end
        end
      end
    end

    def test_drops_current_environment_database_with_url
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(ActiveRecord::Tasks::DatabaseTasks, :drop,
            ["url" => "prod-db-url"]) do
            ActiveRecord::Tasks::DatabaseTasks.drop_current(
              ActiveSupport::StringInquirer.new("production")
            )
          end
        end
      end
    end

    def test_drops_test_and_development_databases_when_env_was_not_specified
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :drop,
            [
              ["database" => "dev-db"],
              ["database" => "test-db"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.drop_current(
              ActiveSupport::StringInquirer.new("development")
            )
          end
        end
      end
    end

    def test_drops_testand_development_databases_when_rails_env_is_development
      old_env = ENV["RAILS_ENV"]
      ENV["RAILS_ENV"] = "development"

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :drop,
            [
              ["database" => "dev-db"],
              ["database" => "test-db"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.drop_current(
              ActiveSupport::StringInquirer.new("development")
            )
          end
        end
      end
    ensure
      ENV["RAILS_ENV"] = old_env
    end
  end

  class LegacyDatabaseTasksDropCurrentThreeTierTest < ActiveRecord::TestCase
    def setup
      @old_config_setting = ActiveRecord::Base.use_legacy_configurations
      ActiveRecord::Base.use_legacy_configurations = true

      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end

      @configurations = {
        "development" => { "primary" => { "database" => "dev-db" }, "secondary" => { "database" => "secondary-dev-db" } },
        "test" => { "primary" => { "database" => "test-db" }, "secondary" => { "database" => "secondary-test-db" } },
        "production" => { "primary" => { "url" => "abstract://prod-db-url" }, "secondary" => { "url" => "abstract://secondary-prod-db-url" } }
      }

      ActiveRecord::Base.configurations = @configurations
    end

    def teardown
      ActiveRecord::Base.use_legacy_configurations = @old_config_setting
      ActiveRecord::Base.configurations = @old_configurations
    end

    def test_drops_current_environment_database
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :drop,
            [
              ["database" => "test-db"],
              ["database" => "secondary-test-db"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.drop_current(
              ActiveSupport::StringInquirer.new("test")
            )
          end
        end
      end
    end

    def test_drops_current_environment_database_with_url
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :drop,
            [
              ["url" => "prod-db-url"],
              ["url" => "secondary-prod-db-url"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.drop_current(
              ActiveSupport::StringInquirer.new("production")
            )
          end
        end
      end
    end

    def test_drops_test_and_development_databases_when_env_was_not_specified
      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :drop,
            [
              ["database" => "dev-db"],
              ["database" => "secondary-dev-db"],
              ["database" => "test-db"],
              ["database" => "secondary-test-db"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.drop_current(
              ActiveSupport::StringInquirer.new("development")
            )
          end
        end
      end
    end

    def test_drops_testand_development_databases_when_rails_env_is_development
      old_env = ENV["RAILS_ENV"]
      ENV["RAILS_ENV"] = "development"

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :drop,
            [
              ["database" => "dev-db"],
              ["database" => "secondary-dev-db"],
              ["database" => "test-db"],
              ["database" => "secondary-test-db"]
            ]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.drop_current(
              ActiveSupport::StringInquirer.new("development")
            )
          end
        end
      end
    ensure
      ENV["RAILS_ENV"] = old_env
    end
  end

  if current_adapter?(:SQLite3Adapter) && !in_memory_db?
    class LegacyDatabaseTasksMigrateTest < ActiveRecord::TestCase
      self.use_transactional_tests = false

      # Use a memory db here to avoid having to rollback at the end
      setup do
        migrations_path = MIGRATIONS_ROOT + "/valid"
        file = ActiveRecord::Base.connection.raw_connection.filename
        @conn = ActiveRecord::Base.establish_connection adapter: "sqlite3",
          database: ":memory:", migrations_paths: migrations_path
        source_db = SQLite3::Database.new file
        dest_db = ActiveRecord::Base.connection.raw_connection
        backup = SQLite3::Backup.new(dest_db, "main", source_db, "main")
        backup.step(-1)
        backup.finish
      end

      teardown do
        @conn.release_connection if @conn
        ActiveRecord::Base.establish_connection :arunit
      end

      def test_migrate_set_and_unset_verbose_and_version_env_vars
        verbose, version = ENV["VERBOSE"], ENV["VERSION"]
        ENV["VERSION"] = "2"
        ENV["VERBOSE"] = "false"

        # run down migration because it was already run on copied db
        assert_empty capture_migration_output

        ENV.delete("VERSION")
        ENV.delete("VERBOSE")

        # re-run up migration
        assert_includes capture_migration_output, "migrating"
      ensure
        ENV["VERBOSE"], ENV["VERSION"] = verbose, version
      end

      def test_migrate_set_and_unset_empty_values_for_verbose_and_version_env_vars
        verbose, version = ENV["VERBOSE"], ENV["VERSION"]

        ENV["VERSION"] = "2"
        ENV["VERBOSE"] = "false"

        # run down migration because it was already run on copied db
        assert_empty capture_migration_output

        ENV["VERBOSE"] = ""
        ENV["VERSION"] = ""

        # re-run up migration
        assert_includes capture_migration_output, "migrating"
      ensure
        ENV["VERBOSE"], ENV["VERSION"] = verbose, version
      end

      def test_migrate_set_and_unset_nonsense_values_for_verbose_and_version_env_vars
        verbose, version = ENV["VERBOSE"], ENV["VERSION"]

        # run down migration because it was already run on copied db
        ENV["VERSION"] = "2"
        ENV["VERBOSE"] = "false"

        assert_empty capture_migration_output

        ENV["VERBOSE"] = "yes"
        ENV["VERSION"] = "2"

        # run no migration because 2 was already run
        assert_empty capture_migration_output
      ensure
        ENV["VERBOSE"], ENV["VERSION"] = verbose, version
      end

      private
        def capture_migration_output
          capture(:stdout) do
            ActiveRecord::Tasks::DatabaseTasks.migrate
          end
        end
    end
  end

  class LegacyDatabaseTasksMigrateErrorTest < ActiveRecord::TestCase
    self.use_transactional_tests = false

    def test_migrate_raise_error_on_invalid_version_format
      version = ENV["VERSION"]

      ENV["VERSION"] = "unknown"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.migrate }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "0.1.11"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.migrate }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "1.1.11"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.migrate }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "0 "
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.migrate }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "1."
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.migrate }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "1_"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.migrate }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "1_name"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.migrate }
      assert_match(/Invalid format of target version/, e.message)
    ensure
      ENV["VERSION"] = version
    end

    def test_migrate_raise_error_on_failed_check_target_version
      ActiveRecord::Tasks::DatabaseTasks.stub(:check_target_version, -> { raise "foo" }) do
        e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.migrate }
        assert_equal "foo", e.message
      end
    end

    def test_migrate_clears_schema_cache_afterward
      assert_called(ActiveRecord::Base, :clear_cache!) do
        ActiveRecord::Tasks::DatabaseTasks.migrate
      end
    end
  end

  class LegacyDatabaseTasksPurgeCurrentTest < ActiveRecord::TestCase
    def test_purges_current_environment_database
      @old_config_setting = ActiveRecord::Base.use_legacy_configurations
      ActiveRecord::Base.use_legacy_configurations = true

      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end

      configurations = {
        "development" => { "database" => "dev-db" },
        "test"        => { "database" => "test-db" },
        "production"  => { "database" => "prod-db" }
      }

      ActiveRecord::Base.configurations = configurations

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :purge,
            ["database" => "prod-db"]
          ) do
            assert_called_with(ActiveRecord::Base, :establish_connection, [:production]) do
              ActiveRecord::Tasks::DatabaseTasks.purge_current("production")
            end
          end
        end
      end
    ensure
      ActiveRecord::Base.use_legacy_configurations = @old_config_setting
      ActiveRecord::Base.configurations = @old_configurations
    end
  end

  class LegacyDatabaseTasksPurgeAllTest < ActiveRecord::TestCase
    def test_purge_all_local_configurations
      @old_config_setting = ActiveRecord::Base.use_legacy_configurations
      ActiveRecord::Base.use_legacy_configurations = true

      assert_deprecated do
        @old_configurations = ActiveRecord::Base.configurations
      end

      configurations = { development: { "database" => "my-db" } }

      ActiveRecord::Base.configurations = configurations

      assert_deprecated do
        ActiveRecord::Base.configurations do
          assert_called_with(
            ActiveRecord::Tasks::DatabaseTasks,
            :purge,
            ["database" => "my-db"]
          ) do
            ActiveRecord::Tasks::DatabaseTasks.purge_all
          end
        end
      end
    ensure
      ActiveRecord::Base.use_legacy_configurations = @old_config_setting
      ActiveRecord::Base.configurations = @old_configurations
    end
  end

  class LegacyDatabaseTaskTargetVersionTest < ActiveRecord::TestCase
    def test_target_version_returns_nil_if_version_does_not_exist
      version = ENV.delete("VERSION")
      assert_nil ActiveRecord::Tasks::DatabaseTasks.target_version
    ensure
      ENV["VERSION"] = version
    end

    def test_target_version_returns_nil_if_version_is_empty
      version = ENV["VERSION"]

      ENV["VERSION"] = ""
      assert_nil ActiveRecord::Tasks::DatabaseTasks.target_version
    ensure
      ENV["VERSION"] = version
    end

    def test_target_version_returns_converted_to_integer_env_version_if_version_exists
      version = ENV["VERSION"]

      ENV["VERSION"] = "0"
      assert_equal ENV["VERSION"].to_i, ActiveRecord::Tasks::DatabaseTasks.target_version

      ENV["VERSION"] = "42"
      assert_equal ENV["VERSION"].to_i, ActiveRecord::Tasks::DatabaseTasks.target_version

      ENV["VERSION"] = "042"
      assert_equal ENV["VERSION"].to_i, ActiveRecord::Tasks::DatabaseTasks.target_version
    ensure
      ENV["VERSION"] = version
    end
  end

  class LegacyDatabaseTaskCheckTargetVersionTest < ActiveRecord::TestCase
    def test_check_target_version_does_not_raise_error_on_empty_version
      version = ENV["VERSION"]
      ENV["VERSION"] = ""
      assert_nothing_raised { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
    ensure
      ENV["VERSION"] = version
    end

    def test_check_target_version_does_not_raise_error_if_version_is_not_setted
      version = ENV.delete("VERSION")
      assert_nothing_raised { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
    ensure
      ENV["VERSION"] = version
    end

    def test_check_target_version_raises_error_on_invalid_version_format
      version = ENV["VERSION"]

      ENV["VERSION"] = "unknown"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "0.1.11"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "1.1.11"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "0 "
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "1."
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "1_"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
      assert_match(/Invalid format of target version/, e.message)

      ENV["VERSION"] = "1_name"
      e = assert_raise(RuntimeError) { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
      assert_match(/Invalid format of target version/, e.message)
    ensure
      ENV["VERSION"] = version
    end

    def test_check_target_version_does_not_raise_error_on_valid_version_format
      version = ENV["VERSION"]

      ENV["VERSION"] = "0"
      assert_nothing_raised { ActiveRecord::Tasks::DatabaseTasks.check_target_version }

      ENV["VERSION"] = "1"
      assert_nothing_raised { ActiveRecord::Tasks::DatabaseTasks.check_target_version }

      ENV["VERSION"] = "001"
      assert_nothing_raised { ActiveRecord::Tasks::DatabaseTasks.check_target_version }

      ENV["VERSION"] = "001_name.rb"
      assert_nothing_raised { ActiveRecord::Tasks::DatabaseTasks.check_target_version }
    ensure
      ENV["VERSION"] = version
    end
  end

  class LegacyDatabaseTasksCheckSchemaFileTest < ActiveRecord::TestCase
    def test_check_schema_file
      assert_called_with(Kernel, :abort, [/awesome-file.sql/]) do
        ActiveRecord::Tasks::DatabaseTasks.check_schema_file("awesome-file.sql")
      end
    end
  end

  class LegacyDatabaseTasksCheckSchemaFileDefaultsTest < ActiveRecord::TestCase
    def test_check_schema_file_defaults
      ActiveRecord::Tasks::DatabaseTasks.stub(:db_dir, "/tmp") do
        assert_equal "/tmp/schema.rb", ActiveRecord::Tasks::DatabaseTasks.schema_file
      end
    end
  end

  class LegacyDatabaseTasksCheckSchemaFileSpecifiedFormatsTest < ActiveRecord::TestCase
    { ruby: "schema.rb", sql: "structure.sql" }.each_pair do |fmt, filename|
      define_method("test_check_schema_file_for_#{fmt}_format") do
        ActiveRecord::Tasks::DatabaseTasks.stub(:db_dir, "/tmp") do
          assert_equal "/tmp/#{filename}", ActiveRecord::Tasks::DatabaseTasks.schema_file(fmt)
        end
      end
    end
  end
end
