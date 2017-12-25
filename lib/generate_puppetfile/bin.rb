# encoding: utf-8
require 'generate_puppetfile'
require 'generate_puppetfile/optparser'
require 'fileutils'
require 'tempfile'
require 'json'
require 'mkmf'
require 'colorize'
require 'uri'

module GeneratePuppetfile
  # Internal: The Bin class contains the logic for calling generate_puppetfile at the command line
  class Bin
    Module_Regex        = %r{^\s*mod ['\"]([a-z0-9_]+\/[a-z0-9_]+)['\"](,\s+['\"](\d+\.\d+\.\d+)['\"])?\s*$}
    Repository_Regex    = %r{^\s*mod\s+['\"](\w+)['\"]\s*,\s*$}
    Location_Only_Regex = %r{^\s+:git\s+=>\s+['\"](\S+)['\"]\s*$}
    Location_Plus_Regex = %r{^\s+:git\s+=>\s+['\"](\S+)['\"]\s*,\s*$}
    Type_ID_Regex       = %r{^\s+:(\w+)\s+=>\s+['\"](\S+)['\"]\s*$}
    Forge_Regex         = %r{^forge}
    Blanks_Regex        = %r{^\s*$}
    Comments_Regex      = %r{^\s*#}
    Skipall_Regex       = %r{^forge|^\s*$|^#}

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
      @options = {}         # Options hash
      @workspace = nil      # Working directory for module download and inspection
      @module_data = {}     # key: modulename, value: version number
      @repository_data = [] # Non-forge modules. Array of hashes containing name, location, type, and ID
      @download_errors = '' # A list of errors encountered while downloading modules. Should remain empty.
    end

    # Public: Run generate-puppetfile at the command line.
    #
    # Returns an Integer exit code for the shell ($?)
    def run
      @options = GeneratePuppetfile::OptParser.parse(@args)

      helpmsg = "generate-puppetfile: try 'generate-puppetfile --help' for more information."

      if (@options[:fixtures_only] && ! @options[:puppetfile] )
        $stderr.puts "generate-puppetfile: --fixtures-only is only valid when a '-p <Puppetfile>' is used as well.\n".red
        puts helpmsg
        return 1
      end

      if @args[0].nil? && (! @options[:puppetfile])
        $stderr.puts "generate-puppetfile: No modules or existing Puppetfile specified.\n".red
        puts helpmsg
        return 1
      end

      unless verify_puppet_exists
        $stderr.puts "generate-puppetfile: Could not find a 'puppet' executable.".red
        $stderr.puts "  Please make puppet available in your path before trying again.\n".red
        return 1
      end


      forge_module_list = []

      # When using --fixtures-only, simply parse the provided Puppetfile and get out
      if @options[:fixtures_only] && @options[:puppetfile]
        @module_data = generate_module_data_from_Puppetfile
        @repository_data = generate_repository_data_from_Puppetfile
        fixtures_data = generate_fixtures_data
        write_fixtures_data(fixtures_data)
        return 0
      end

      # For everything else, run through the whole thing
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
      # Currently, ALL statements not including a forge module are listed as extras. The @repository_data should be removed from the extras eventually (#54)
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
      @module_data = generate_module_data_from_modulepath
      puppetfile_contents = generate_puppetfile_contents(extras)

      if @download_errors == ''
        create_puppetfile(puppetfile_contents) if @options[:create_puppetfile]
        display_puppetfile(puppetfile_contents) unless @options[:silent]

        if @options[:create_fixtures]
          @repository_data = generate_repository_data_from_Puppetfile if @options[:puppetfile]
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
          next if line =~ Forge_Regex
          next if line =~ Blanks_Regex
          next if line =~ /#{Puppetfile_Header}/
          next if line =~ /#{Extras_Note}/

          puppetfile_contents[:extras].push(line)
        end
      end

      puppetfile_contents
    end

    # Public: Read and parse the contents of an existing Puppetfile
    def read_puppetfile_with_versions(puppetfile)
      puppetfile_contents = {
        modules: [],
        extras: []
      }

      File.foreach(puppetfile) do |line|
        if Module_Regex.match(line)
          name    = Regexp.last_match(1)
          version = Regexp.last_match(3)
          print "    #{name} looks like a forge module.\n" if @options[:debug]
          puppetfile_contents[:modules].push([name, version])
        else
          next if line =~ Forge_Regex
          next if line =~ Blanks_Regex
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

    # Public: generate the module data from the modulepath (@workspace)
    def generate_module_data_from_modulepath
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

    # Public: generate the module data from an existing Puppetfile
    def generate_module_data_from_Puppetfile
      puppetfile_contents = read_puppetfile_with_versions(@options[:puppetfile])

      modules = {}
      puppetfile_contents[:modules].each do |name, version|
        modules[name] = version
        $stderr.puts "Module #{name} has a version of #{version}, it may be deprecated. For more information, visit https://forge.puppet.com/#{name}".blue if version =~ /999/ and ! @options[:silent]
      end

      modules
    end

    # Public: generate the ad hoc repository (non-forge module) data from an existing Puppetfile
    #   Returns an array of hashes with keys name, location, type, id
    def generate_repository_data_from_Puppetfile
      repositories = []

      # Open the Puppetfile
      File.open(@options[:puppetfile], 'r') do |fh|
        while (line = fh.gets) != nil
          # Skip blank lines, comments, anything that looks like a forge module
          next if line =~ Skipall_Regex
          next if Module_Regex.match(line)
          # When we see /mod 'modulename',/ it is possibly a properly formatted fixture
          if Repository_Regex.match(line)
            complete = false
            name = Regexp.last_match(1)
            while (line = fh.gets) != nil
              next if line =~ Skipall_Regex
              if Location_Only_Regex.match(line)
                # The Puppetfile may specify just a location /:git => 'https://github.com/author/puppet-modulename'/
                # We do not validate the URI protocol, just that it is a valid URI
                location = Regexp.last_match(1)
                puts "Found module #{name} with location #{location}" if @options[:debug]
                unless location.match(URI.regexp)
                  puts "#{location} is not a valid URI, skipping this repo" if @options[:debug]
                  break
                end
                repositories << {name: name, location: location}
                complete = true
              elsif Location_Plus_Regex.match(line)
                # Or it may provide more, with a trailing comma
                #   :git => 'https://github.com/author/puppet-modulename',
                #   :ref => '1.0.0'
                location = Regexp.last_match(1)
                while (line = fh.gets) != nil
                  next if line =~ Skipall_Regex
                  if Type_ID_Regex.match(line)
                    type = Regexp.last_match(1)
                    id   = Regexp.last_match(2)
                    puts "Found module #{name} with location #{location}, #{type} of #{id}" if @options[:debug]
                    unless location.match(URI.regexp)
                      puts "#{location} is not a valid URI, skipping this repo" if @options[:debug]
                      break
                    end
                    repositories << {name: name, location: location, type: type, id: id}
                    complete = true
                  else
                    # If the :git line ends with a comma but no type/ID is found, ignore it, we cannot properly determine the fixture
                    puts "Found module #{name} at location #{location}. Expected type/ID information but did not find any, skipping." if @options[:debug]
                    complete = true
                  end
                  break if complete
                end
              else
                # If the /mod 'modulename',/ line is not followed with a :git string, ignore it, we cannot properly determine the fixture
                puts "Found a reference to module #{name} but no location (:git) was provided, skipping." if @options[:debug]
                complete = true
              end
              break if complete
            end
          end
        end
      end

      repositories
    end


    # Public: generate the list of modules in Puppetfile format from the @workspace
    def generate_forge_module_output
      return '' if @module_data.empty?

      max_length    = @module_data.keys.max_by {|mod| mod.length}.length + 3 # room for extra chars
      module_output = ''

      @module_data.each do |modulename, version|
        module_output += sprintf("mod %-#{max_length}s '%s'\n", "'#{modulename}',", version)
      end
      module_output
    end

    # Public: Generate a new Puppetfile's contents based on a list of modules
    # and any extras found in an existing Puppetfile.
    #
    # extras is an array of strings
    def generate_puppetfile_contents(extras)
      puppetfile_contents = <<-EOF
forge 'https://forge.puppet.com'

#{Puppetfile_Header}
      EOF

      puppetfile_contents += generate_forge_module_output

      puppetfile_contents += "#{Extras_Note}\n" unless extras == []
      extras.each do |line|
        puppetfile_contents += line.to_s
      end unless extras == []

      # Strip out all contents with --ignore_comments
      puppetfile_contents.gsub!(/^#.*$\n/, '') if @options[:ignore_comments]

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

      unless @repository_data.empty?
        fixtures_data += "  repositories:\n"
        @repository_data.each do |repodata|
          # Each repository has two or  pieces of data
          #   Mandatory: the module name, the URI/location
          #   Optional: the type (ref, branch, commit, etc.) and ID (tag, branch name, commit hash, etc.)
          name      = repodata[:name]
          location  = repodata[:location]
          type      = repodata[:type]
          id        = repodata[:id]

          data = <<-EOF
    #{name}:
      repo: "#{location}"
          EOF
          data += "      #{type}: \"#{id}\"\n" if (type && id)

          fixtures_data += data
        end
      end


      unless @module_data.empty?
        fixtures_data += "  forge_modules:\n"
        @module_data.keys.each do |modulename|
          shortname = modulename.split('/')[1]
          version = @module_data[modulename] 
          data = <<-EOF
    #{shortname}:
      repo: "#{modulename}"
      ref: "#{version}"
          EOF
          data.gsub!(/^ *ref.*$\n/, '') unless version != nil

          fixtures_data += data
        end
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
