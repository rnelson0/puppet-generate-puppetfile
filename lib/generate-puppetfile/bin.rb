require 'generate-puppetfile/optparser'

class GeneratePuppetfile::Bin
  def initialize(args)
    @args = args
  end

  def run
    opts = GeneratePuppetfile::OptParser.build

    helpmsg = "generate-puppetfile: try 'generate-puppetfile --help' for more information."
    begin
      opts.parse!(@args)
    rescue OptionParser::InvalidOption
      puts "generate-puppetfile: #{$!.message}"
      puts helpmsg
      return 1
    end

    if @args[0].nil?
      puts "generate-puppetfile: No modules or existing Puppetfile specified."
      puts helpmsg
      return 1
    end

    @args.each do |modulename|
      puts "x"
      puts "User provided module name of #{modulename}"
    end
    return return_val
  end
end
