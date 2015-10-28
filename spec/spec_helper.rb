require 'generate_puppetfile'
require 'rspec/its'

RSpec.configure do |config|
  config.mock_framework = :rspec
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
