# encoding: utf-8
require 'generate_puppetfile'
require 'generate_puppetfile/optparser'
require 'fileutils'

module GeneratePuppetfile
  # Internal: The Bin class contains the logic for calling generate_puppetfile at the command line
  class Bin
    Module_regex = Regexp.new("mod ['\"]([a-z0-9_]+\/[a-z0-9_]+)['\"](, ['\"](\\d\.\\d\.\\d)['\"])?", Regexp::IGNORECASE)
    @options = {}

    # Public: Initialize a new GeneratePuppetfile::Bin
    #
    # args - Array of command line arguments as Strings to be passed to GeneratePuppetfile::OptParser.parse
    #
    # Example:
    #
    #   GeneratePuppetfile::Bin.new(ARGV).run
    def initialize(args)
      @args = args
    end

    # Public: Run generate-puppetfile at the command line.
    #
    # Returns an Integer exit code for the shell ($?)
    def run
      @options = GeneratePuppetfile::OptParser.parse(@args)

      helpmsg = "generate-puppetfile: try 'generate-puppetfile --help' for more information."

      if @args[0].nil? && (! @options[:puppetfile])
        puts "generate-puppetfile: No modules or existing Puppetfile specified."
        puts helpmsg
        return 1
      end

      forge_module_list = Array.new

      if @args
	puts "\nProcessing modules from the command line...\n\n" if @options[:debug]
        cli_modules = Array.new
        @args.each do |modulename|
	  validate(modulename) && (cli_modules.push(modulename))
        end
      end

      puppetfile_contents = Hash.new
      extras = Array.new
      if @options[:puppetfile]
	puts "\nProcessing the puppetfile '#{@options[:puppetfile]}'...\n\n" if @options[:debug]
	puppetfile_contents = read_puppetfile(@options[:puppetfile])
	extras = puppetfile_contents[:extras]
      end

      forge_module_list.push(*cli_modules) if @args
      forge_module_list.push(*puppetfile_contents[:modules]) if puppetfile_contents[:modules]

      list_forge_modules(forge_module_list) if puppetfile_contents && @options[:debug]
      list_extras(puppetfile_contents[:extras]) if puppetfile_contents[:extras] && @options[:debug]

      generate_puppetfile_contents(forge_module_list, puppetfile_contents[:extras])

      return 0
    end

    # Public: Validates that a provided module name is valid.
    def validate (modulename)
      success = (modulename =~ /[a-z0-9_]\/[a-z0-9_]/i)
      puts "    '#{modulename}' is not a valid module name. Skipping." unless success
      success
    end

    # Public: Display the list of Forge modules collected.
    def list_forge_modules (module_list)
      puts "\nListing discovered modules from CLI and/or Puppetfile:\n\n"
      module_list.each do |name|
	puts "    #{name}"
      end
      puts ""
    end

    # Public: Display the list of extra statements found in the Puppetfile.
    def list_extras (extras)
      puts "\nExtras found in the existing Puppetfile:\n\n"
      extras.each do |line|
	puts "    #{line}"
      end
      puts ""
    end

    # Public: Read and parse the contents of an existing Puppetfile
    def read_puppetfile (puppetfile)
      puppetfile_contents = {
	:modules => Array.new,
	:extras  => Array.new,
      }

      File.foreach(puppetfile) do |line|
	if Module_regex.match(line)
	  name = $1
	  print "    #{name} looks like a forge module.\n" if @options[:debug]
	  puppetfile_contents[:modules].push(name)
	else
	  next if line =~ /^forge/
	  next if line =~ /^\s+$/
	  next if line =~ /# Discovered elements from existing Puppetfile/

	  puppetfile_contents[:extras].push(line)
	end
      end

      puppetfile_contents
    end

    # Public: Generate a new Puppetfile's contents based on a list of modules
    # and any extras found in an existing Puppetfile.
    #
    # module_list is an array of forge module names to be downloaded
    # extras is an array of strings
    def generate_puppetfile_contents (module_list, extras = [])
      workspace = `mktemp -d`

      modulepath = "--modulepath #{workspace.chomp} "
      silence    = '>/dev/null 2>&1 '
      strip_colors = 'sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"'

      puts "\nInstalling modules. This may take a few minutes.\n"
      module_list.each do |name|
	command  = "puppet module install #{name} "
	command += modulepath + silence
	
	system(command)
      end

      puppetfile_header = <<-EOF
forge 'http://forge.puppetlabs.com'

# Modules discovered by generate-puppetfile
      EOF

      puppetfile_body = `puppet module list #{modulepath} 2>/dev/null | #{strip_colors}`

      puppetfile_body.gsub!(/^\/.*$/, '')
      puppetfile_body.gsub!(/-/,    '/')
      puppetfile_body.gsub!(/├── /, "mod '")
      puppetfile_body.gsub!(/└── /, "mod '")
      puppetfile_body.gsub!(/ \(v/, "', '")
      puppetfile_body.gsub!(/\)$/,  "'")
      puppetfile_body.gsub!(/^$\n/, '')

      puppetfile_footer = "# Discovered elements from existing Puppetfile\n"
      extras.each do |line|
	puppetfile_footer += "#{line}"
      end if extras

      puts <<-EOF


Your Puppetfile has been generated. Copy and paste between the markers:

=======================================================================
#{puppetfile_header}
#{puppetfile_body}
#{puppetfile_footer}
=======================================================================
      EOF

      FileUtils.rm_rf(workspace)
    end
  end
end
