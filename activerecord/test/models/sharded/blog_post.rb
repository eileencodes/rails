# frozen_string_literal: true

module Sharded
  class BlogPost < ActiveRecord::Base
    self.table_name = :sharded_blog_posts

    belongs_to :blog
    has_many :comments, foreign_key: [:blog_id, :blog_post_id], primary_key: [:blog_id, :id]
  end
end
