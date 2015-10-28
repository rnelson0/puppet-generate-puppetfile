[![Gem Version](https://badge.fury.io/rb/generate-puppetfile.svg)](https://badge.fury.io/rb/generate-puppetfile)

Tired of searching for dependencies on the forge and hoping you got everything? Have an existing Puppetfile that's getting long in the tooth? Use generate-puppetfile to generate a list of modules and their dependencies, at the latest version, in Puppetfile format for use with r10k or librarian-puppet.

## Installation

    gem install generate-puppetfile

## Usage

Run `generate-puppetfile` with a list of modules and/or an existing Puppetfile. Each module name will be validated to be of the proper format (author/name). Any existing Puppetfile will be scanned for forge modules. Non-forge module entries will be preserved. All forge modules will be tracked at the latest version, along with their dependencies. The resulting Puppetfile will contain all the forge modules along with any preserved non-forge module statements.

### Forge Modules Only
```
$ generate-puppetfile echocat/nfs rnelson0/certs

Installing modules. This may take a few minutes.


Your Puppetfile has been generated. Copy and paste between the markers:

=======================================================================
forge 'http://forge.puppetlabs.com'

# Modules discovered by generate-puppetfile

mod 'echocat/nfs', '1.7.1'
mod 'herculesteam/augeasproviders_core', '2.1.2'
mod 'herculesteam/augeasproviders_shellvar', '2.2.0'
mod 'puppetlabs/concat', '1.2.4'
mod 'puppetlabs/stdlib', '4.9.0'
mod 'rnelson0/certs', '0.6.2'

# Discovered elements from existing Puppetfile

=======================================================================

```

### Using an existing Puppetfile
```
$ generate-puppetfile -p git/puppetinabox/controlrepo/Puppetfile

Installing modules. This may take a few minutes.


Your Puppetfile has been generated. Copy and paste between the markers:

=======================================================================
forge 'http://forge.puppetlabs.com'

# Modules discovered by generate-puppetfile

mod 'ajjahn/dhcp', '0.2.0'
mod 'croddy/make', '0.0.5'
mod 'garethr/erlang', '0.3.0'
mod 'gentoo/portage', '2.3.0'
mod 'golja/gnupg', '1.2.1'
mod 'maestrodev/rvm', '1.12.1'
mod 'nanliu/staging', '1.0.3'
mod 'palli/createrepo', '1.1.0'
mod 'puppetlabs/activemq', '0.4.0'
mod 'puppetlabs/apache', '1.6.0'
mod 'puppetlabs/apt', '2.2.0'
mod 'puppetlabs/concat', '1.2.4'
mod 'puppetlabs/firewall', '1.7.1'
mod 'puppetlabs/gcc', '0.3.0'
mod 'puppetlabs/git', '0.4.0'
mod 'puppetlabs/inifile', '1.4.2'
mod 'puppetlabs/java', '1.4.2'
mod 'puppetlabs/java_ks', '1.3.1'
mod 'puppetlabs/lvm', '0.5.0'
mod 'puppetlabs/mcollective', '99.99.99'
mod 'puppetlabs/mysql', '3.6.1'
mod 'puppetlabs/ntp', '4.1.0'
mod 'puppetlabs/pe_gem', '0.1.1'
mod 'puppetlabs/postgresql', '4.6.0'
mod 'puppetlabs/puppetdb', '5.0.0'
mod 'puppetlabs/rabbitmq', '5.3.1'
mod 'puppetlabs/ruby', '0.4.0'
mod 'puppetlabs/stdlib', '4.9.0'
mod 'puppetlabs/tftp', '0.2.3'
mod 'puppetlabs/vcsrepo', '1.3.1'
mod 'puppetlabs/xinetd', '1.5.0'
mod 'richardc/datacat', '0.5.0'
mod 'rnelson0/certs', '0.6.2'
mod 'rnelson0/local_user', '1.0.1'
mod 'saz/ssh', '2.8.1'
mod 'saz/sudo', '3.1.0'
mod 'stahnma/epel', '1.1.1'
mod 'stephenrjohnson/puppet', '1.3.1'
mod 'thias/bind', '0.5.1'
mod 'yguenane/augeas', '0.1.1'
mod 'yguenane/ygrpms', '0.1.0'
mod 'zack/r10k', '3.1.1'

# Discovered elements from existing Puppetfile
# Modules from the Puppet Forge
# Modules from Github
mod 'lab_config',
  :git => 'git@github.com:puppetinabox/lab_config.git'

=======================================================================
```

## Limitations

* Parsing of an existing Puppetfile is naive. Anything that doesn't look like a forge module is preserved and then added to the end of the new Puppetfile. Verify that no ordering errors are introduced before using the new file.

## Thanks
Many thanks to the following people for contributing to generate-puppetfile
* [Tomy Lobo](https://github.com/TomyLobo)
* [Ben Ford](https://github.com/binford2k)

## Contributing

All issues and PRs are welcome!
