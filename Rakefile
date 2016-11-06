require 'rake'
require 'rspec/core/rake_task'
require 'github_changelog_generator/task'

task default: :test

RSpec::Core::RakeTask.new(:test)

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.future_release = ENV['future_release'] if ENV['future_release']
end
