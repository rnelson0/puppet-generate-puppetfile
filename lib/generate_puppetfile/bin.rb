# encoding: utf-8
require 'generate_puppetfile'
require 'generate_puppetfile/optparser'
require 'fileutils'

module GeneratePuppetfile
  class Bin
    Module_regex = Regexp.new("mod ['\"]([a-z0-9_]+\/[a-z0-9_]+)['\"](, ['\"](\\d\.\\d\.\\d)['\"])?", Regexp::IGNORECASE)

    def initialize(args)
      @args = args
    end

    def run
      options = GeneratePuppetfile::OptParser.parse(@args)

      helpmsg = "generate-puppetfile: try 'generate-puppetfile --help' for more information."

      if @args[0].nil? && (! options[:puppetfile])
        puts "generate-puppetfile: No modules or existing Puppetfile specified."
        puts helpmsg
        return 1
      end

      forge_module_list = Array.new

      if @args
	puts "Processing modules from the command line..."
        cli_modules = Array.new
        @args.each do |modulename|
	  validate(modulename) && (cli_modules.push(modulename))
        end

	if options[:debug]
          puts "Modules from the CLI:"
	  cli_modules.each do |name|
	    puts "    #{name}"
	  end
	end
      end

      puppetfile_contents = Hash.new
      extras = Array.new
      if options[:puppetfile]
	puts "Processing the puppetfile '#{options[:puppetfile]}'..."
	puppetfile_contents = read_puppetfile(options[:puppetfile])
	extras = puppetfile_contents[:extras]

	if options[:debug]
	  puts "Modules from the Puppetfile:"
	  puppetfile_contents[:modules].each do |name|
	    puts "    #{name}"
	  end
	end
      end

      forge_module_list.push(*cli_modules) if @args
      forge_module_list.push(*puppetfile_contents[:modules]) if puppetfile_contents[:modules]

      list_modules(forge_module_list) if puppetfile_contents
      list_extras(puppetfile_contents[:extras]) if puppetfile_contents[:extras]

      generate_puppetfile_contents(forge_module_list, puppetfile_contents[:extras])
    end

    def validate (modulename)
      success = (modulename =~ /[a-z0-9_]\/[a-z0-9_]/i)
      puts "'#{modulename}' is not a valid module name. Skipping." unless success
      success
    end

    def list_modules (module_list)
      puts "Starting to list modules"
      module_list.each do |name|
	puts name
      end
    end

    def list_extras (extras)
      extras.each do |line|
	puts line
      end
    end

    def read_puppetfile (puppetfile)
      puppetfile_contents = {
	:modules => Array.new,
	:extras  => Array.new,
      }

      File.foreach(puppetfile) do |line|
	print "GOT #{line}"
	if Module_regex.match(line)
	  print "  (looks like a forge module)\n"
	  name = $1
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

    def generate_puppetfile_contents (module_list, extras = [])
      # cli_modules is a hash of module name => version
      # puppetfile_contents is a hash with two keys:
      #   module_list is a hash of module name => version
      #   extras is an array of strings
      workspace = `mktemp -d`

      modulepath = "--modulepath #{workspace.chomp} "
      silence    = '>/dev/null 2>&1 '
      strip_colors = 'sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"'
      module_list.each do |name|
	command  = "puppet module install #{name} "
	command += modulepath + silence
	
	system(command)
      end

      puppetfile_header = <<-EOF
forge 'http://forge.puppetlabs.com'

# Modules discovered by generate-puppetfile
      EOF

      puppetfile_body = `puppet module list #{modulepath} | #{strip_colors} 2>/dev/null`

      puppetfile_body.gsub!(/^\/.*$/, '')
      puppetfile_body.gsub!(/-/,    '/')
      puppetfile_body.gsub!(/├── /, "mod '")
      puppetfile_body.gsub!(/└── /, "mod '")
      puppetfile_body.gsub!(/ \(v/, "', '")
      puppetfile_body.gsub!(/\)$/,  '')

      puppetfile_footer = "# Discovered elements from existing Puppetfile\n"
      extras.each do |line|
	puppetfile_footer += "#{line}"
      end

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
