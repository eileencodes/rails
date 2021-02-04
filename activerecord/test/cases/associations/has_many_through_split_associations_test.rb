# frozen_string_literal: true

require "cases/helper"
require "models/post"
require "models/author"
require "models/comment"

class HasManyThroughSplitAssociationsTest < ActiveRecord::TestCase
  fixtures :posts, :authors, :comments

  def setup
    @author = authors(:mary)
  end

  def test_counting_on_split_through
    assert_equal @author.comments.count, @author.split_comments.count
    assert_queries(2) { @author.split_comments.count }
    assert_queries(1) { @author.comments.count }
  end

  def test_pluck_on_split_through
    assert_equal @author.comments.pluck(:id), @author.split_comments.pluck(:id)
    assert_queries(2) { @author.split_comments.pluck(:id) }
    assert_queries(1) { @author.comments.pluck(:id) }
  end

  def test_fetching_on_split_through
    assert_equal @author.comments.first.id, @author.split_comments.first.id
    assert_queries(2) { @author.split_comments.first.id }
    assert_queries(1) { @author.comments.first.id }
  end

  def test_to_a_on_split_through
    assert_equal @author.comments.to_a, @author.split_comments.to_a
    @author.reload
    assert_queries(2) { @author.split_comments.to_a }
    assert_queries(1) { @author.comments.to_a }
  end

  #def test_appending_on_split_through
  #  assert_difference(->() { @author.split_comments.reload.size }) do
  #    @author.posts.create(title: "ducks", body: "fly together")
  #  end
  #  assert_queries(2) { @author.split_comments.reload.size }
  #  assert_queries(1) { @author.comments.to_reload.size }
  #end
end
