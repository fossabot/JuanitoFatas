require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#links_to" do
    it "opens a new link with microdata and aria-friendly options" do
      result = helper.links_to(
        "Juanito Fatas",
        "juanitofatas.com",
        class: "blog",
        aria_text: "JuanitoFatas's website"
      )

      expect(result).to eq %(<a class="blog" aria_text="JuanitoFatas&#39;s website" target="_blank" rel="noopener" itemprop="url" href="juanitofatas.com">Juanito Fatas</a>)
    end
  end
end
