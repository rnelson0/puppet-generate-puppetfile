require 'rake'
require 'rspec/core/rake_task'
require 'github_changelog_generator/task'

task default: :test

RSpec::Core::RakeTask.new(:test)

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.future_release = ENV['future_release'] if ENV['future_release']
  config.user = 'rnelson0'
  config.project = 'puppet-generate-puppetfile'
  config.future_release = File.read('lib/generate_puppetfile/version.rb').match(%r{VERSION\s+=\s+'([0-9.]*)'})[1]
end
