# frozen_string_literal: true

class PostCreator
  TitleNotFound = Class.new(StandardError)

  def self.run(title)
    new(title).run
  end

  def initialize(title)
    raise(TitleNotFound, "Please specify post's title") unless title
    @title = title
    @time = Time.current
  end

  def run
    create_file
    insert_content
    display_message
  end

  private

    attr_reader :title, :time

    def posts_folder
      Rails.root.join("lib/tasks/blog_posts/_posts")
    end

    def date
      time.strftime("%Y-%m-%d")
    end

    def datetime
      time.strftime("%Y-%m-%d %H:%M:%S")
    end

    def normalized_title
      title.parameterize
    end

    def new_post_filename
      @_new_post_filename ||= posts_folder.join("#{date}-#{normalized_title}.md")
    end

    def create_file
      FileUtils.touch(new_post_filename) unless File.exists?(new_post_filename)
    end

    def post_content
      <<~POST_CONTENT.sub("$title", title).sub("$date", datetime)
        ---
        layout: post
        title: $title
        date: $date
        description:
        tags:
        ---
      POST_CONTENT
    end

    def insert_content
      File.open new_post_filename, "w+" do |file|
        file.puts(post_content)
      end
    end

    def display_message
      $stdout.puts "#{new_post_filename} created."
    end
end
