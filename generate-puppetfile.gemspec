require 'date'
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'generate_puppetfile/version'

Gem::Specification.new do |s|
  s.name        = 'generate-puppetfile'
  s.version     = GeneratePuppetfile::VERSION
  s.date        = Date.today.to_s
  s.summary     = 'Generate a Puppetfile'
  s.description = 'Generate a Puppetfile for use with r10k based on an existing file or a list of modules.'
  s.authors     = ['Rob Nelson']
  s.email       = 'rnelson0@gmail.com'
  s.executables = %w( generate-puppetfile )
  s.files       = ["bin/generate-puppetfile"]
  s.files      += %w( README.md )
  s.files      += Dir.glob("lib/**/*")
  s.homepage    = 'https://github.com/rnelson0/puppet-generate-puppetfile'
  s.license     = 'MIT'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-its', '~> 1'
  s.add_development_dependency 'json', '~> 1'
  s.add_development_dependency 'puppet'
end
