source "https://rubygems.org"

ruby "2.3.1"

gem "rails", ">= 5.0.5"
gem "pg", "~> 0.21"
gem "puma", "~> 3.9"
gem "slim-rails"
gem "sass-rails", "~> 5.0"
gem "uglifier", ">= 1.3.0"
gem "jquery-rails"
gem "turbolinks", "~> 5"
gem "lograge"
gem "html-pipeline"
gem "github-markdown"
gem "sanitize"
gem "twemoji"
gem "html-pipeline-linkify_github"
gem "html-pipeline-rouge_filter"
gem "rollbar"
gem "secure_headers"
gem "bourbon", "~> 5.0.0.beta.6"
gem "neat", "~> 1.8.0"
gem "title"
gem "rack-rewrite"
gem "skylight"
gem "redis"
gem "gemoji"
gem "nokogiri", ">= 1.7.1"

group :production do
  gem "rack-timeout"
  gem "rails_12factor"
end

group :development, :test do
  gem "dotenv-rails"
  gem "pry-rails"
  gem "rspec-rails"
end

group :development do
  gem "octokit", "~> 4.7.0"
  gem "web-console"
  gem "listen", "~> 3.1.5"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :test do
  gem "database_rewinder"
  gem "factory_girl_rails"
  gem "shoulda-matchers"
  gem "webmock"
  gem "launchy"
  gem "capybara"
  gem "capybara-webkit"
  gem "codecov", require: false
end
