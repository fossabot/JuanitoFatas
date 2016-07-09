# frozen_string_literal: true

class MigratePost
  def initialize(content)
    @content = content
  end

  def call
    post = Post.find_by(title: title) || Post.new(title: title)
    post.update!(body: body, description: description, created_at: date)
    post
  end

  private

    attr_reader :content

    def fetch_yml_value(line)
      line.split(/:\s+/).last.gsub(?", "")
    end

    def lines
      @_lines ||= content.split("\n")
    end

    def title
      fetch_yml_value(lines[2])
    end

    def date
      fetch_yml_value(lines[3])
    end

    def description
      fetch_yml_value(lines[4])
    end

    def body
      (lines[6].empty? ? lines[7..-1] : lines[6..-1]).join("\n") + "\n"
    end
end

class Migrator
  def initialize(posts)
    @posts = posts
  end

  def call
    posts.each do |post|
      puts "Migrating #{post}"
      migrated_post = MigratePost.new(IO.read(post)).call
      puts "Post#<id: #{migrated_post.id}, title: #{migrated_post.title}>"
    end
  end

  private

    attr_reader :posts
end