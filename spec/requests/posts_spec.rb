require "rails_helper"

RSpec.describe "Posts" do
  describe "#index" do
    it "set Surrogate-Key from posts" do
      travel_to Time.zone.local(2017, 1, 1, 0, 0, 0) do
        first_post = create(:post, id: 1)
        second_post = create(:post, id: 2)

        get "/blog"

        expect(response.headers.to_h).to include(
          "Surrogate-Key" => "posts #{first_post.cache_key} #{second_post.cache_key}"
        )
      end
    end
  end

  describe "#show" do
    it "set Surrogate-Key from post id and updated_at timestamp" do
      travel_to Time.zone.local(2017, 1, 1, 0, 0, 0) do
        post = create(
          :post,
          id: 42,
          title: "Example Post",
          updated_at: Time.current.tomorrow
        )

        get "/blog/#{post.slug}"

        expect(response.headers.to_h).to include(
          "Surrogate-Key" => post.cache_key
        )
      end
    end
  end
end
