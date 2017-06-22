require "rails/generators/named_base"

module TestUnit # :nodoc:
  module Generators # :nodoc:
    class Base < Rails::Generators::NamedBase # :nodoc:
      def depends_on_system_test?
        !(options[:skip_system_test] || options[:skip_test] || options[:api])
      end
    end
  end
end
