require "abstract_unit"


class AssertionsHelperTest < ActionSystemTestCase
  setup do
    @session = RailsApp
    @session.visit('/posts')
  end

  def test_all_of_selectors
    @session.assert_all_of_selectors(:title_test, 'the title', 'the others')
  end

  def test_none_of_selectors
    @session.assert_none_of_selectors(:title_test, 'the whatever', 'the test')
  end
end
