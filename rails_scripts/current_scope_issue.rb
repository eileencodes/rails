# frozen_string_literal: true

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :org_size
    t.string :type
  end
end

class User < ActiveRecord::Base
end

class Organization < User
  scope :a_filter, -> (filter) do
    some_method(filter, scope: current_scope)
  end

  def self.some_method(filter, scope:)
    scope.where(org_size: filter)
  end
end

class BugTest < Minitest::Test
  def test_unscoped_with_block_stuff
    org = User.create! name: 'GitHub', org_size: 'Medium', type: 'Organization'

    # will fail on master and 5-2-stable because `current_scope` is nil
    assert_equal 1, Organization.a_filter('Medium').count
  end
end
