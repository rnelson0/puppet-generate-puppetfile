require 'generate_puppetfile'
require 'optparse'

module GeneratePuppetfile
  class OptParser
    def self.parse(args)
      options = {}
      opts = OptionParser.new do |opts|
        opts.banner = "generate-puppetfile [OPTIONS] [<MODULE> ... <MODULE>]"

        opts.on('-p', '--puppetfile FILE', 'Name of existing Puppetfile to verify and update') do |file|
	  options[:puppetfile] = file
        end

	opts.on('-d', '--debug', 'Enable debug logging') do
	  options[:debug] = true
	end

	opts.on_tail('-v', '--version', 'Show version') do
	  puts "generate-puppetfile v#{GeneratePuppetfile::VERSION}"
	end
      end
     
      opts.parse!(args)
      options
    end
  end
end
