# encoding: utf-8
require 'fileutils'
require 'generate_puppetfile'
require 'generate_puppetfile/optparser'
require 'json'
require 'mkmf'
require 'rugged'
require 'tempfile'
require 'uri'

module GeneratePuppetfile
  # Internal: The Bin class contains the logic for calling generate_puppetfile at the command line
  class Bin
    Module_Regex = Regexp.new("mod ['\"]([a-z0-9_]+\/[a-z0-9_]+)['\"](, ['\"](\\d\.\\d\.\\d)['\"])?", Regexp::IGNORECASE)
    @options = {}    # Options hash
    @workspace = nil # Working directory for module download and inspection
    Silence = '>/dev/null 2>&1 '.freeze
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
        $stderr.puts 'generate-puppetfile: No modules or existing Puppetfile specified.'
        puts helpmsg
        return 1
      end

      unless verify_puppet_exists
        $stderr.puts "generate-puppetfile: Could not find a 'puppet' executable."
        $stderr.puts '  Please make puppet available in your path before trying again.'
        return 1
      end

      forge_module_list = []
      git_module_list = []

      if @args
        puts "\nProcessing modules from the command line...\n\n" if @options[:debug]
        cli_forge_modules = []
        cli_git_modules = []
        @args.each do |modulename|
          validate_forge_module(modulename) && cli_forge_modules.push(modulename) && continue
          validate_git_module(modulename) && cli_git_modules.push(modulename)
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
      list_git_modules(git_module_list) if puppetfile_contents && @options[:debug]
      list_extras(puppetfile_contents[:extras]) if puppetfile_contents[:extras] && @options[:debug]

      abort("\nNo valid modules or existing Puppetfile content was found. Exiting.\n\n") unless forge_module_list != [] || puppetfile_contents[:extras] != []

      create_workspace
      @modulepath = "--modulepath #{@workspace} "

      download_forge_modules(forge_module_list)
      download_git_modules(git_module_list)
      puppetfile_contents = generate_puppetfile_contents(extras)

      create_puppetfile(puppetfile_contents) if @options[:create_puppetfile]

      display_puppetfile(puppetfile_contents) unless @options[:silent]

      if @options[:create_fixtures]
        fixtures_data = generate_fixtures_data
        write_fixtures_data(fixtures_data)
      end

      cleanup_workspace

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

    # Public: Validates that a provided forge module name is valid.
    def validate_forge_module(modulename)
      success = (modulename =~ /[a-z0-9_]\/[a-z0-9_]/i)
      $stderr.puts "'#{modulename}' is not a valid module name. Skipping." unless success
      success
    end

    # Public: Validates that a provided git module name is valid.
    def validate_git_module(modulename)
      success = URI(modulename) rescue URI::Error
      $stderr.puts "'#{modulename}' is not a valid module URI. Skipping." unless success
      success
    end

    # Public: Display the list of Forge modules collected.
    def list_forge_modules(module_list)
      unless @options[:silent]
        puts "\nListing discovered forge modules from CLI and/or Puppetfile:\n\n"
        module_list.each do |name|
          puts "    #{name}"
        end
        puts ''
      end
    end

    # Public: Display the list of git modules collected.
    def list_git_modules(module_list)
      unless @options[:silent]
        puts "\nListing discovered git modules from CLI and/or Puppetfile:\n\n"
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

    # Public: Download the list of forge modules and their dependencies to @workspace
    #
    # forge_module_list is an array of forge module names to be downloaded
    def download_forge_modules(forge_module_list)
      puts "\nInstalling forge modules. This may take a few minutes.\n" unless @options[:silent]
      forge_module_list.each do |name|
        next if _download_forge_module(name)
        $stderr.puts "There was a problem with the module name '#{name}'."
        $stderr.puts '  Check that module exists as you spelled it and/or your connectivity to the puppet forge.'
        exit 2
      end
    end

    # Private: Download an individual forge module
    #
    # _download_forge_module
    def _download_forge_module(name)
      command  = "puppet module install #{name} "
      command += @modulepath + Silence

      puts "Calling '#{command}'" if @options[:debug]
      system(command)
    end

    # Public: Download the list of git modules to @workspace
    #
    # git_module_list is an array of git URI to be downloaded
    def download_forge_modules(forge_module_list)
      puts "\nInstalling git modules. This may take a few minutes.\n" unless @options[:silent]
      git_module_list.each do |name|
        next if _download_git_module(name)
        $stderr.puts "There was a problem with the module named '#{name}'."
        $stderr.puts '  Check that the module exists at the url listed and/or your connectivity to the git repo.'
        exit 2
      end
    end

    # Private: Download an individual git module
    #
    # _download_git_module
    def _download_git_module(git_url)
      Rugged::Repository.clone_at(git_url, git_url.path.partition(%r{[\w-]+\/[\w-]+})[1].split('-')[-1]) rescue Rugged::Error
    end

    # Public: generate the list of modules in Puppetfile format from the @workspace
    def generate_module_output
      module_output = `puppet module list #{@modulepath} 2>/dev/null`

      module_output.gsub!(/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/, '') # Strips ANSI color codes
      module_output.gsub!(/^\/.*$/, '')
      module_output.tr!('-', '/')
      module_output.gsub!(/├── /,   "mod '")
      module_output.gsub!(/└── /,   "mod '")
      module_output.gsub!(/ \(v/,   "', '")
      module_output.gsub!(/\)$/,    "'")
      module_output.gsub!(/^$\n/,   '')

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

      puppetfile_contents += generate_module_output

      puppetfile_contents += "#{Extras_Note}\n" unless extras == []
      extras.each do |line|
        puppetfile_contents += line.to_s
      end unless extras == []

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

      # Header for fixtures file creates a symlink for the current module"
      fixtures_data = <<-EOF
fixtures:
  symlinks:
    #{@options[:modulename]}: "\#{source_dir}"
      EOF

      module_directories = Dir.glob("#{@workspace}/*")
      fixtures_data += "  repositories:\n" unless module_directories.empty?
      module_directories.each do |module_directory|
        name = File.basename(module_directory)
        file = File.read("#{module_directory}/metadata.json")
        source = JSON.parse(file)['source']
        fixtures_data += "    #{name}: #{source}\n"
        puts "Found a module '#{name}' with a project page of #{source}." if @options[:debug]
      end unless module_directories == []

      fixtures_data
    end

    def write_fixtures_data(data)
      File.open('.fixtures.yml', 'w') do |file|
        file.write data
      end
    end
  end
end
