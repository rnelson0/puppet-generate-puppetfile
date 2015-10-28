[![Gem Version](https://badge.fury.io/rb/generate-puppetfile.svg)](https://badge.fury.io/rb/generate-puppetfile)

Tired of searching for dependencies on the forge and hoping you got everything? Use generate-puppetfile to generate a list of modules and their dependencies in a Puppetfile format for use with r10k or librarian-puppet.

To use this, simply clone the repository and run the generate-puppetfile script with a list of valid module names:

```
$ ./generate-puppetfile echocat/nfs rnelson0/certs
Download echocat/nfs and its dependencies...
Download rnelson0/certs and its dependencies...
Module download complete. Generating Puppetfile.

Here is your suggested Puppetfile:
----------------------------------

forge 'http://forge.puppetlabs.com'

mod 'echocat/nfs', '1.7.1'
mod 'herculesteam/augeasproviders_core', '2.1.2'
mod 'herculesteam/augeasproviders_shellvar', '2.2.0'
mod 'puppetlabs/concat', '1.2.4'
mod 'puppetlabs/stdlib', '4.9.0'
mod 'rnelson0/certs', '0.6.2'
```
