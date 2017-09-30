require "rails_helper"

RSpec.describe Post do
  describe ".with_tag" do
    it "returns post with given tag" do
      swift_post = create(:post, tags: ["swift"])
      objc_post = create(:post, tags: ["objective-c"])

      expect(Post.with_tag("swift")).to eq [swift_post]
    end
  end

  describe ".all_tags" do
    it "returns all tags in the system as a hash" do
      create(:post, tags: %w(ruby rails rubygem))
      create(:post, tags: %w(swift ios))
      create(:post, tags: %w(web design rails))

      result = Post.all_tags

      expect(result.keys).to match_array %w(d i r s w)
      expect(result.values.flatten).to match_array %w(ruby rubygem swift ios web design rails)
    end
  end

  describe ".newest_first" do
    it "returns the posts: newest to oldest" do
      oldest_post = create(:post, created_at: 1.year.ago)
      middle_post = create(:post, created_at: 1.week.ago)
      newest_post = create(:post, created_at: 1.day.ago)

      expect(Post.newest_first).to eq [newest_post, middle_post, oldest_post]
    end
  end

  describe "#create" do
    it "generates a slug" do
      post = build(:post, title: "Make Ruby Great Again")

      post.save

      expect(post.slug).to eq(
        File.join Time.current.strftime("%Y/%m/%d"), "make_ruby_great_again"
      )
    end
  end

  describe "#cache_key" do
    it "by record key and updated_at timestamp" do
      travel_to Time.zone.local(2017, 1, 1, 0, 0, 0) do
        post = create(:post, id: 42)

        result = post.cache_key

        expect(result).to eq "posts/42/2017-01-01 00:00:00 UTC"
      end
    end
  end
end
