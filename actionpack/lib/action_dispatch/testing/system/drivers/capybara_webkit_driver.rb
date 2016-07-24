require 'capybara-webkit'

module AbstractDriver
  module CapybaraWebkitDriver
    Capybara.javascript_driver = :webkit
  end
end
