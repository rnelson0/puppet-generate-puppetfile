# encoding: utf-8
require 'generate_puppetfile'
require 'generate_puppetfile/optparser'
require 'fileutils'
require 'tempfile'
require 'json'
require 'mkmf'
require 'colorize'

module GeneratePuppetfile
  # Internal: The Bin class contains the logic for calling generate_puppetfile at the command line
  class Bin
    Module_Regex = Regexp.new("mod ['\"]([a-z0-9_]+\/[a-z0-9_]+)['\"](, ['\"](\\d\.\\d\.\\d)['\"])?", Regexp::IGNORECASE)
    @options = {}         # Options hash
    @workspace = nil      # Working directory for module download and inspection
    @module_data = {}     # key: modulename, value: version number
    @download_errors = '' # A list of errors encountered while downloading modules. Should remain empty.
    Silence = ('>' + File::NULL.to_str + ' 2>&1 ').freeze
    Puppetfile_Header = '# Modules discovered by generate-puppetfile'.freeze
    Extras_Note = '# Discovered elements from existing Puppetfile'.freeze

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
        $stderr.puts 'generate-puppetfile: No modules or existing Puppetfile specified.'.red
        puts helpmsg
        return 1
      end

      unless verify_puppet_exists
        $stderr.puts "generate-puppetfile: Could not find a 'puppet' executable.".red
        $stderr.puts '  Please make puppet available in your path before trying again.'.red
        return 1
      end

      forge_module_list = []

      if @args
        puts "\nProcessing modules from the command line...\n\n" if @options[:debug]
        cli_modules = []
        @args.each do |modulename|
          validate(modulename) && cli_modules.push(modulename)
        end
        if cli_modules == [] && ! @options[:puppetfile]
          $stderr.puts "No valid modules were found to process.".red
          return 1
        end
      end

      puppetfile_contents = {}
      extras = []
      if @options[:puppetfile]
        puts "\nProcessing the puppetfile '#{@options[:puppetfile]}'...\n\n" if @options[:debug]
        puppetfile_contents = read_puppetfile(@options[:puppetfile])
        extras = puppetfile_contents[:extras]
      end

      forge_module_list.push(*cli_modules) if @args
      forge_module_list.push(*puppetfile_contents[:modules]) if puppetfile_contents[:modules]
      list_forge_modules(forge_module_list) if puppetfile_contents && @options[:debug]
      list_extras(puppetfile_contents[:extras]) if puppetfile_contents[:extras] && @options[:debug]

      unless forge_module_list != [] || puppetfile_contents[:extras] != []
        $stderr.puts "\nNo valid modules or existing Puppetfile content was found. Exiting.\n\n".red
        return 1
      end

      create_workspace
      @modulepath = "--modulepath #{@workspace} "

      return 2 if download_modules(forge_module_list) == 2
      @module_data = generate_module_data
      puppetfile_contents = generate_puppetfile_contents(extras)

      if @download_errors == ''
        create_puppetfile(puppetfile_contents) if @options[:create_puppetfile]
        display_puppetfile(puppetfile_contents) unless @options[:silent]

        if @options[:create_fixtures]
          fixtures_data = generate_fixtures_data
          write_fixtures_data(fixtures_data)
        end

        cleanup_workspace
      else
        $stderr.puts @download_errors
        display_puppetfile(puppetfile_contents) unless @options[:silent]
        return 2
      end

      0
    end

    # Public: Display the generated Puppetfile to STDOUT with delimiters
    def display_puppetfile(puppetfile_contents)
      puts <<-EOF

Your Puppetfile has been generated. Copy and paste between the markers:

=======================================================================
#{puppetfile_contents.chomp}
=======================================================================
      EOF
    end

    # Public: Create a Puppetfile on disk
    # The Puppetfile will be called 'Puppetfile' in the current working directory
    def create_puppetfile(puppetfile_contents)
      File.open('Puppetfile', 'w') do |file|
        file.write puppetfile_contents
      end
    end

    # Public: Validates that a provided module name is valid.
    def validate(modulename)
      success = (modulename =~ /[a-z0-9_][\/-][a-z0-9_]/i)
      $stderr.puts "'#{modulename}' is not a valid module name. Skipping.".red unless success
      success
    end

    # Public: Display the list of Forge modules collected.
    def list_forge_modules(module_list)
      unless @options[:silent]
        puts "\nListing discovered modules from CLI and/or Puppetfile:\n\n"
        module_list.each do |name|
          puts "    #{name}"
        end
        puts ''
      end
    end

    # Public: Display the list of extra statements found in the Puppetfile.
    def list_extras(extras)
      unless @options[:silent] || (extras == [])
        puts "\nExtras found in the existing Puppetfile:\n\n"
        extras.each do |line|
          puts "    #{line}"
        end
        puts ''
      end
    end

    # Public: Read and parse the contents of an existing Puppetfile
    def read_puppetfile(puppetfile)
      puppetfile_contents = {
        modules: [],
        extras: []
      }

      File.foreach(puppetfile) do |line|
        if Module_Regex.match(line)
          name = Regexp.last_match(1)
          print "    #{name} looks like a forge module.\n" if @options[:debug]
          puppetfile_contents[:modules].push(name)
        else
          next if line =~ /^forge/
          next if line =~ /^\s+$/
          next if line =~ /#{Puppetfile_Header}/
          next if line =~ /#{Extras_Note}/

          puppetfile_contents[:extras].push(line)
        end
      end

      puppetfile_contents
    end

    # Public: Verify that Puppet is available in the path
    def verify_puppet_exists
      MakeMakefile::Logging.instance_variable_set(:@logfile, File::NULL)
      find_executable0('puppet')
    end

    # Public: Download the list of modules and their dependencies to @workspace
    #
    # module_list is an array of forge module names to be downloaded
    def download_modules(module_list)
      puts "\nInstalling modules. This may take a few minutes.\n\n" unless @options[:silent]

      @download_errors = ''
      module_list.each do |name|
        next if _download_module(name)
        @download_errors << "There was a problem with the module name '#{name}'.".red + "\n"
      end

      if @download_errors != ''
        @download_errors << '  Check that modules exist as under the listed name, and/or your connectivity to the puppet forge.'.red + "\n\n"
        @download_errors << 'Here is the PARTIAL Puppetfile that would have been generated.'.red + "\n\n\n"
      end
    end

    # Private: Download an individual module
    #
    # _download_module
    def _download_module(name)
      command  = "puppet module install #{name} "
      command += @modulepath + Silence

      puts "Calling '#{command}'" if @options[:debug]
      system(command)
    end

    # Public: generate the module data the @workspace
    def generate_module_data
      command = "puppet module list #{@modulepath} 2>#{File::NULL}"
      puts "Calling '#{command}'" if @options[:debug]
      module_output = `#{command}`

      module_output.gsub!(/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/, '') # Strips ANSI color codes
      modules = {}
      module_output.each_line do |line|
        next unless line =~ / \(v/
        line.tr!('-', '/')
        line.gsub!(/^\S* /, '')
        line += line
        name, version = line.match(/(\S+) \(v(.+)\)/).captures
        modules[name] = version
        $stderr.puts "Module #{name} has a version of #{version}, it may be deprecated. For more information, visit https://forge.puppet.com/#{name}".blue if version =~ /999/ and ! @options[:silent]
      end
      modules
    end

    # Public: generate the list of modules in Puppetfile format from the @workspace
    def generate_forge_module_output
      module_output = ''
      @module_data.keys.each do |modulename|
        module_output += "mod '#{modulename}', '#{@module_data[modulename]}'\n"
      end
      module_output
    end

    # Public: Generate a new Puppetfile's contents based on a list of modules
    # and any extras found in an existing Puppetfile.
    #
    # extras is an array of strings
    def generate_puppetfile_contents(extras)
      puppetfile_contents = <<-EOF
forge 'http://forge.puppetlabs.com'

#{Puppetfile_Header}
      EOF

      puppetfile_contents += generate_forge_module_output

      puppetfile_contents += "#{Extras_Note}\n" unless extras == []
      extras.each do |line|
        puppetfile_contents += line.to_s
      end unless extras == []

      # Strip out all contents with --ignore_comments
      puppetfile_contents.gsub! /^#.*$\n/ ,'' if @options[:ignore_comments]

      puppetfile_contents
    end

    # Public: Create a temporary workspace for module manipulation
    def create_workspace
      @workspace = Dir.mktmpdir.chomp
    end

    # Public: Remove the workspace (with prejudice)
    def cleanup_workspace
      FileUtils.rm_rf(@workspace)
    end

    # Public: Generate a simple fixtures file.
    def generate_fixtures_data
      puts "\nGenerating .fixtures.yml using module name #{@options[:modulename]}" unless @options[:silent]

      # Determine if there are symlinks, either for the default modulename, or for anything in the modulepath
      symlinks = []
      modulepath = ''
      if (File.exists?('environment.conf') and environment_conf = File.read('environment.conf'))
        puts "\nGenerating .fixtures.yml for a controlrepo." unless @options[:silent]

        environment_conf.split("\n").each do |line|
          modulepath = (line.split('='))[1].gsub(/\s+/,'') if line =~ /^modulepath/
        end

        paths = modulepath.split(':').delete_if { |path| path =~ /^\$/ }
        paths.each do |path|
          Dir["#{path}/*"].each do |module_location|
            module_name = File.basename(module_location)
            module_path = module_location
            symlinks << {
              :name => module_name,
              :path => '"#{source_dir}/' + module_path + '"',
            }
          end
        end
      else
        puts "\nGenerating .fixtures.yml using module name #{@options[:modulename]}." unless @options[:silent]

        symlinks << { 
          :name => @options[:modulename],
          :path => '"#{source_dir}"',
        }
      end

      # Header for fixtures file creates symlinks for the controlrepo's modulepath, or for the current module"
      fixtures_data = "fixtures:\n"
      if symlinks
        fixtures_data += "  symlinks:\n"
        symlinks.each do |symlink|
          fixtures_data += "    #{symlink[:name]}: #{symlink[:path]}\n"
        end
      end

      fixtures_data += "  forge_modules:\n" if @module_data != {}
      @module_data.keys.each do |modulename|
        shortname = modulename.split('/')[1]
        version = @module_data[modulename]
        fixtures_data += <<-EOF
    #{shortname}:
      repo: "#{modulename}"
      ref: "#{version}"
        EOF
      end

      fixtures_data
    end

    def write_fixtures_data(data)
      File.open('.fixtures.yml', 'w') do |file|
        file.write data
      end
    end
  end
end
