require_relative "../../post_migration/posts_migrator"

namespace :blog_posts do
  desc "Migrate existing blog posts"
  task migrate: :environment do
    PostsMigrator.new(Dir[Rails.root.join("lib/tasks/blog_posts/_posts/*.md")]).call
  end
end
