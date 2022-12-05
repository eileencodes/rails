# frozen_string_literal: true

module Sharded
  class Comment < ActiveRecord::Base
    self.table_name = :sharded_comments

    belongs_to :blog_post, foreign_key: [:blog_id, :blog_post_id], primary_key: [:blog_id, :id]
    belongs_to :blog
  end
end
