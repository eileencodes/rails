# frozen_string_literal: true

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :organizations, force: true do |t|
    t.string :name
  end
end

class Organization < ActiveRecord::Base
  scope :with_block, -> (org) do
    unscoped do
      all
    end
  end

  scope :without_block, -> (org) do
    unscoped.all
  end
end

class BugTest < Minitest::Test
  # pass
  def test_unscoped_without_block_stuff
    org = Organization.create! name: 'GitHub'

    assert_equal Organization.all.to_sql, Organization.where(id: org.id).without_block(org).to_sql
  end

  # fail
  def test_unscoped_with_block_stuff
    org = Organization.create! name: 'GitHub'

    # The problem is we're essentially calling `org_where` with `all`. In the non-block version
    # we're not doing that
    # org_where.unscoped { org_where.all }.to_sql
    assert_equal Organization.all.to_sql, Organization.where(id: org.id).with_block(org).to_sql
  end
end
