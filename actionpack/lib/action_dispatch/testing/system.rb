require 'capybara/rails'

module ActionDispatch
  module System

  end

  class SystemTest < ActiveSupport::TestCase
    module Behavior
      extend ActiveSupport::Concern
      include Capybara::DSL
    end

    include Behavior
  end
end
