# frozen_string_literal: true

module ActiveRecord
  class DatabaseConfigurations
    def initialize(configurations = [])
      @configurations = build_configs(configurations)
    end

    attr_reader :configurations

    def default_config_hash(env = ActiveRecord::ConnectionHandling::DEFAULT_ENV.call.to_s)
      default = select_db_config(env)
      default.config if default
    end

    def select_db_config(env)
      configurations.find do |db_config|
        db_config.env_name == env.to_s ||
          (db_config.for_current_env? && db_config.spec_name == env.to_s)
      end
    end

    # Collects the configs for the environment and optionally the specification
    # name passed in.
    #
    # If a spec name is provided a single DatabaseConfiguration object will be
    # returned, otherwise an array of DatabaseConfiguration objects will be returned
    # the correspond with the environment requested.
    def configs_for(env, spec = nil, &blk)
      env_with_configs = configurations.select do |db_config|
        db_config.env_name == env
      end

      if spec
        env_with_configs.find do |db_config|
          db_config.spec_name == spec
        end
      else
        env_with_configs
      end
    end

    def build_configs(configs)
      return configs.configurations if configs.is_a?(DatabaseConfigurations)

      build_db_config = configs.each_pair.flat_map do |env_name, config|
        walk_configs(env_name, "primary", config)
      end.compact

      if url = ENV["DATABASE_URL"]
        build_url_config(url, build_db_config)
      else
        build_db_config
      end
    end

    # Walks all the configs passed in and returns an array
    # of DatabaseConfig objects for each configuration that
    # are either a HashConfig or a UrlConfig.

    # i think all this work may be the responsibility of the DbConfig object.
    # then it can use inheritance to create the right one? maybe for later. this
    # is exhausting.
    def walk_configs(env_name, spec_name, config)
      case config
      when String
        build_db_config_from_string(env_name, spec_name, config)
      when Hash
        build_db_config_from_hash(env_name, spec_name, config)
      end
    end

    def build_db_config_from_string(env_name, spec_name, config)
      begin
        url = config
        uri = URI.parse(url)
        if uri.try(:scheme)
          ActiveRecord::DatabaseConfiguration::UrlConfig.new(env_name, spec_name, url)
        end
      rescue URI::InvalidURIError
        ActiveRecord::DatabaseConfiguration::HashConfig.new(env_name, spec_name, config)
      end
    end

    def build_db_config_from_hash(env_name, spec_name, config)
      if url = config["url"]
        config_without_url = config.dup
        config_without_url.delete "url"
        ActiveRecord::DatabaseConfiguration::UrlConfig.new(env_name, spec_name, url, config_without_url)
      elsif config.size == 1 || config["database"]
        ActiveRecord::DatabaseConfiguration::HashConfig.new(env_name, spec_name, config)
      else
        config.each_pair.map do |sub_spec_name, sub_config|
          walk_configs(env_name, sub_spec_name, sub_config)
        end
      end
    end

    def build_url_config(url, configs)
      env = ActiveRecord::ConnectionHandling::DEFAULT_ENV.call.to_s

      if original_config = configs.find(&:for_current_env?)
        if original_config.url_config?
          configs
        else
          configs.map do |config|
            ActiveRecord::DatabaseConfiguration::UrlConfig.new(env, config.spec_name, url, config.config)
          end
        end
      else
        configs + [ActiveRecord::DatabaseConfiguration::UrlConfig.new(env, "primary", url)]
      end
    end
  end

  module DatabaseConfiguration # :nodoc:
    class DatabaseConfig
      attr_reader :env_name, :spec_name

      def initialize(env_name, spec_name)
        @env_name = env_name
        @spec_name = spec_name
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
      attr_reader :config

      def initialize(env_name, spec_name, config)
        super(env_name, spec_name)
        @config = config
      end
    end


    class UrlConfig < DatabaseConfig
      attr_reader :url, :config

      def initialize(env_name, spec_name, url, config = {})
        super(env_name, spec_name)
        @config = build_config(config, url)
        @url = url
      end

      def url_config?
        true
      end

      def build_config(original_config, url)
        if url =~ /^jdbc:/
          hash = { "url" => url }
        else
          hash = ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(url).to_hash
        end

        if original_config[env_name]
          original_config[env_name].merge(hash)
        else
          original_config.merge(hash)
        end
      end
    end
  end
end
