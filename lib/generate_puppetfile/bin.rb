require 'generate_puppetfile'
require 'generate_puppetfile/optparser'

module GeneratePuppetfile
  class Bin
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

      forge_module_list = Hash.new
      extra_module_list = Hash.new

      if @args
	puts "Processing modules from the command line..."
        cli_modules = Hash.new
        @args.each do |modulename|
	  validate(modulename) && (cli_modules[modulename] = false)
        end

	if options[:debug]
          puts "Modules from the CLI (no version):"
	  cli_modules.each do | name, version |
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
	  puppetfile_contents[:modules].each do | name, version |
	    puts "    #{name}, #{version}"
	  end
	end
      end

      forge_module_list.merge(cli_modules) if @args
      forge_module_list.merge(puppetfile_contents[:modules]) if puppetfile_contents[:modules]

      list_modules(forge_module_list) if puppetfile_contents
      list_extras(puppetfile_contents[:extras]) if puppetfile_contents[:extras]

      generate_puppetfile_contents(forge_module_list, puppetfile_contents)
    end

    def validate (modulename)
      success = (modulename =~ /[a-z0-9_]\/[a-z0-9_]/i)
      puts "'#{modulename}' is not a valid module name. Skipping." unless success
      success
    end

    def list_modules (module_list)
      module_list.each do |name, version|
	print name
	print ", #{version}" if version
	print "\n"
      end
    end

    def list_extras (extras)
      extras.each do |line|
	puts line
      end
    end

    def read_puppetfile (puppetfile)
      puppetfile_contents = {
	:modules => Hash.new,
	:extras  => Array.new,
      }

      puppetfile_contents
    end

    def generate_puppetfile_contents (module_list, puppetfile_contents)
      # cli_modules is a hash of module name => version
      # puppetfile_contents is a hash with two keys:
      #   module_list is a hash of module name => version
      #   extras is an array of strings

      puts 'generate_puppetfile_contents'
    end
  end
end
