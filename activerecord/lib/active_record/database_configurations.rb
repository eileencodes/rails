# frozen_string_literal: true

module ActiveRecord
  class DatabaseConfigurations
    def initialize(configurations = [])
      if configurations.is_a?(Array)
        @configurations = configurations
      else
        @configurations = format_configs(configurations)
      end
    end

    attr_accessor :configurations

    def default_config(env)
      default = configurations.find { |db_config| db_config.env_name == env }
      default.config if default
    end

    def select_db_config(env)
      configurations.find do |db_config|
        db_config.env_name == env.to_s ||
          (db_config.for_current_env? && db_config.spec_name == env.to_s)
      end
    end

    def config_for_env_and_spec(environment, specification_name)
      configs_for(environment).find do |db_config|
        db_config.spec_name == specification_name
      end
    end

    # Collects the configs for the environment passed in.
    #
    # If a block is given returns the specification name and configuration
    # otherwise returns an array of DatabaseConfig structs for the environment.
    def configs_for(env, &blk)
      configs = configurations

      env_with_configs = configs.select do |db_config|
        db_config.env_name == env
      end

      if block_given?
        env_with_configs.each do |env_with_config|
          yield env_with_config.spec_name, env_with_config.config
        end
      else
        env_with_configs
      end
    end
    alias :[] :configs_for

    # Walks all the configs passed in and returns an array
    # of DatabaseConfig structs for each configuration.
    def walk_configs(env_name, spec_name, config)
      case config
      when String
        uri =  begin
                URI.parse config
               rescue URI::InvalidURIError
                 config
               end

        if uri && uri.try(:scheme)
          ActiveRecord::DatabaseConfiguration::UrlConfig.with_spec(env_name, spec_name, config)
        elsif config.is_a?(Hash)
          ActiveRecord::DatabaseConfiguration::HashConfig.new(env_name, spec_name, config)
        end
      when Hash
        if config["database"] || config["url"]
          if config["url"]
            x = config.dup
            x.delete "url"
            ActiveRecord::DatabaseConfiguration::UrlConfig.with_spec(env_name, spec_name, config["url"], x)
          else
            ActiveRecord::DatabaseConfiguration::HashConfig.new(env_name, spec_name, config)
          end
        else
          if config.size == 1 && config.values.all? { |v| v.is_a? String }
            uri = URI.parse config.values.first
            if uri.scheme
              ActiveRecord::DatabaseConfiguration::UrlConfig.with_spec(env_name, spec_name, config.values.first)
            else
              ActiveRecord::DatabaseConfiguration::HashConfig.new(env_name, spec_name, config)
            end
          else
            config.each_pair.map do |sub_spec_name, sub_config|
              walk_configs(env_name, sub_spec_name, sub_config)
            end
          end
        end
      end
    end

    def format_configs(configs)
      db_configs = configs.each_pair.flat_map do |env_name, config|
        walk_configs(env_name, "primary", config)
      end.compact

      if url = ENV["DATABASE_URL"]
        url_configs(url, db_configs)
      else
        db_configs
      end
    end

    def url_configs(url, configs)
      # Find a matching config, if it exists
      # pass the matching config in to UrlConfig.new
      env = ActiveRecord::ConnectionHandling::DEFAULT_ENV.call.to_s
      existing_config = configs.find(&:for_current_env?)

      if existing_config
        if existing_config.url_config?
          return configs
        end

        configs.map do |config|
          if config == existing_config
            ActiveRecord::DatabaseConfiguration::UrlConfig.new(env, existing_config, url)
          else
            config
          end
        end
      else
        configs + [ActiveRecord::DatabaseConfiguration::UrlConfig.primary(env, url)]
      end
    end
  end

  module DatabaseConfiguration # :nodoc:
    class DatabaseConfig
      attr_reader :env_name

      def initialize(env_name)
        @env_name = env_name
      end

      def url_config?
        false
      end

      def to_legacy_hash
        { env_name => config }
      end

      def for_current_env?
        env_name == ActiveRecord::ConnectionHandling::DEFAULT_ENV.call
      end
    end

    class HashConfig < DatabaseConfig
      attr_reader :spec_name, :config

      def initialize(env_name, spec_name, config)
        super(env_name)
        @spec_name = spec_name
        @config = config
      end
    end

    class UrlConfig < DatabaseConfig
      attr_reader :url, :existing_config

      # MergeConfig is a holder for a blank config that merges values
      # in the hash with the new UrlConfig that's constructed
      MergeConfig = Struct.new(:spec_name, :to_legacy_hash)

      # Used to construct a config object when the URL config has not
      # been merged yet. Ex before `postgres://localhost/foo` gets
      # turned into `{ "adapter" => "postgres", "host => "localhost/foo" }`
      #
      # The NullUrlConfig guarantees there's always an existing config object.
      class NullUrlConfig
        def self.spec_name
          "primary"
        end

        def self.to_legacy_hash
          Hash.new({})
        end
      end

      def self.with_spec(env, spec_name, url, merge_values = {})
        new(env, MergeConfig.new(spec_name, { env => merge_values }), url)
      end

      def self.primary(env, url)
        new(env, NullUrlConfig, url)
      end

      def initialize(env_name, existing_config, url)
        super(env_name)
        @existing_config = existing_config
        @url = url
      end

      def spec_name
        existing_config.spec_name
      end

      def url_config?
        true
      end

      def config
        if url =~ /^jdbc:/
          hash = { "url" => url }
        else
          hash = ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(url).to_hash
        end

        existing_config.to_legacy_hash[env_name].merge(hash)
      end
    end
  end
end
