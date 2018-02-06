# frozen_string_literal: true

require_relative "post_migrator"

class PostsMigrator
  def initialize(posts)
    @posts = posts
  end

  def call
    posts.each do |post|
      puts "Migrating #{post}"
      migrated_post = PostMigrator.new(IO.read(post)).call
      puts "Post#<id: #{migrated_post.id}, title: #{migrated_post.title}>"
    end
  end

  private

    attr_reader :posts
end
