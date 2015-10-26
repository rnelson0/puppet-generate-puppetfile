require 'optparse'

class GeneratePuppetfile::OptParser
  HELP_TEXT = <<-EOF

    generate-puppetfile <MODULE> [<MODULE> ... <MODULE>]
      or
    generate-puppetfile -P PUPPETFILE [<MODULE> ... <MODULE>]

        MODULE       Name of a module on the forge in format 'author/name'
        PUPPETFILE   Location of an existing Puppetfile to verify and update

    Option:
  EOF

  def self.build
    OptionParser.new do |opts|
      opts.banner = HELP_TEXT

      options.on('-p', '--puppetfile FILE', 'Name of existing Puppetfile to verify and update.') do |file|
	# something with the puppetfile
      end
    end
  end
end
