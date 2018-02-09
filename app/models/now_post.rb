class NowPost
  attr_reader :body, :updated_at

  def initialize
    @body = now_post_path.read
    @updated_at = now_post_path.mtime
  end

  private

    def now_post_path
      Rails.root.join("data/now.md")
    end
end
