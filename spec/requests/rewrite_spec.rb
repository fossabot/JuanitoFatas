require "rails_helper"

RSpec.describe "rewrite old routes" do
  it do
    expect(
      get "/2015/05/19/rubygem-configuration-pattern"
    ).to redirect_to(
      "/blog/2015/05/19/rubygem_configuration_pattern"
    )
  end

  it do
    expect(
      get "/blog/2018/02/09/git_data_api_example_in_ruby"
    ).to redirect_to(
      "/blog/2015/12/23/git_data_api_example_in_ruby"
    )
  end
end
