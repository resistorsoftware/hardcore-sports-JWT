source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.1"
gem "mutex_m" # Ruby 3.4 and up will need this gem from now on

gem "rails", "~> 7.2"
gem "pg", "~> 1.1"
gem "redis", "~> 5.0"
gem "puma", "~> 6.0"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "dotenv-rails"
gem "activerecord-session_store"

# shopify
gem "shopify_app", "~> 22.5.1"
gem "polaris_view_components", "~> 2.0"
gem "shopify_graphql"

# frontend
gem "sprockets-rails"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "good_job"

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "http_logger"
end

group :development do
  gem "web-console"
  gem "pry-rails"
  gem "hotwire-livereload"
  gem "standard"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "vcr"
  gem "webmock"
end
