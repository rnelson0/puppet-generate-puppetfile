Gem::Specification.new do |s|
  s.name        = 'generate-puppetfile'
  s.version     = '0.0.0'
  s.date        = '2015-10-26'
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
  s.executables = 'generate-puppetfile'
end
