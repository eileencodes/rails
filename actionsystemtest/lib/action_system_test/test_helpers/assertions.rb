module ActionSystemTest
  module TestHelpers
    # Assertions for system testing that aren't included by default in Capybara.
    # These are assertions that are useful specifically for Rails applications.
    module Assertions
      # Asserts that all of the provided selectors are present on the given page.
      # Using the selector, +:avatar+ for example, asserts that the selector is
      # present with the items passed in. If options are provided, the assertion
      # will check that each item is present with those options as well.
      #
      #   assert_all_of_selectors(:avatar, 'Eileen', 'Jeremy')
      #   assert_all_of_selectors(:avatar, 'Eileen', 'Jeremy', visible: all)
      def assert_all_of_selectors(selector, *items, **options)
        items.each do |item|
          assert_selector selector, item, options
        end
      end

      # Asserts that none of the provided selectors are present on the page.
      # Using the selector, +:avatar+ for example, asserts that the selector
      # is not present with the items passed in. If options are provided,
      # the assertion will check that each item is present with those
      # options as well.
      #
      #   assert_none_of_selectors(:avatar, 'Tom', 'Dan')
      def assert_none_of_selectors(selector, *items, **options)
        items.each do |item|
          assert_no_selector selector, item, options
        end
      end
    end
  end
end
