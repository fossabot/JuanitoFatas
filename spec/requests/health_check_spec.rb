require "rails_helper"

RSpec.describe "rewrite old routes" do
  it "returns 200" do
    get "/are-you-with-me"

    expect(response).to have_http_status(:ok)
  end
end
