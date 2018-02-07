require "rails_helper"

RSpec.feature "Home Page" do
  scenario "anyone views now page" do
    visit "/now"

    expect(page.status_code).to eq 200
    expect(page).to have_text("What I'm doing now")
  end
end
