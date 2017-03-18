require 'generate_puppetfile'
require 'optparse'

module GeneratePuppetfile
  # Internal: Parse the options provided to generate-puppetfile
  class OptParser
    # Internal: Initialize the OptionParser
    #
    # Returns an OptionParser object.
    def self.parse(args)
      options = {}
      # Default values
      options[:modulename] = 'profile'

      opts = OptionParser.new do |opts|
        opts.banner = 'generate-puppetfile [OPTIONS] [<MODULE> ... <MODULE>]'

        opts.on('-p', '--puppetfile FILE', 'Name of existing Puppetfile to verify and update') do |file|
          unless File.readable?(file)
            puts "\nPuppetfile '#{file}' cannot be read. Are you sure you passed in the correct filename?\n\n"
            exit 1
          end

          options[:puppetfile] = file
        end

        opts.on('-c', '--create_puppetfile', 'Create a Puppetfile in the working directory. Warning: overwrites any existing file with the same name.') do
          options[:create_puppetfile] = true
        end

        opts.on('-f', '--create-fixtures', 'Create a .fixtures.yml file in the working directory. This works in a module directory or at the top if your controlrepo..') do
          options[:create_fixtures] = true
        end

        opts.on('-m', '--modulename NAME', "Name of the module the fixtures file will be used with. Optional, for use with --create-fixtures when used in a module directory. Defaults to 'profile'. ") do |name|
          options[:modulename] = name
        end

        opts.on('-s', '--silent', 'Run in silent mode. Supresses all non-debug output. Adds the -c flag automatically.') do
          options[:silent] = true
          options[:create_puppetfile] = true
        end

        opts.on('-d', '--debug', 'Enable debug logging') do
          options[:debug] = true
        end

        opts.on_tail('-i', '--ignore-comments', 'Ignore comments') do
          options[:ignore_comments] = true
        end

        opts.on_tail('-v', '--version', 'Show version') do
          puts "generate-puppetfile v#{GeneratePuppetfile::VERSION}"
          exit
        end
      end

      opts.parse!(args)
      options
    end
  end
end
