# Changelog

## [1.1.0](https://github.com/rnelson0/puppet-generate-puppetfile/tree/1.1.0) (2019-11-29)

[Full Changelog](https://github.com/rnelson0/puppet-generate-puppetfile/compare/v1.0.0...1.1.0)

**Closed issues:**

- generate-puppetfile command not found [\#68](https://github.com/rnelson0/puppet-generate-puppetfile/issues/68)

**Merged pull requests:**

- \# update readme for pdk & bolt use cases [\#75](https://github.com/rnelson0/puppet-generate-puppetfile/pull/75) ([abuxton](https://github.com/abuxton))
- Sort fixtures.yml, add --latest-versions flag, misc bug fixes [\#69](https://github.com/rnelson0/puppet-generate-puppetfile/pull/69) ([nabertrand](https://github.com/nabertrand))
- Make regexes case-insensitive [\#66](https://github.com/rnelson0/puppet-generate-puppetfile/pull/66) ([rnelson0](https://github.com/rnelson0))

## [v1.0.0](https://github.com/rnelson0/puppet-generate-puppetfile/tree/v1.0.0) (2018-01-02)

[Full Changelog](https://github.com/rnelson0/puppet-generate-puppetfile/compare/v0.11.0...v1.0.0)

**Closed issues:**

- Unsecure forge url for generated Puppetfile [\#58](https://github.com/rnelson0/puppet-generate-puppetfile/issues/58)
- generate-puppetfile ignores Git modules whose name contains a slash [\#56](https://github.com/rnelson0/puppet-generate-puppetfile/issues/56)
- Add support for git repos in .fixture.yml [\#54](https://github.com/rnelson0/puppet-generate-puppetfile/issues/54)
- Add support for updating from git [\#25](https://github.com/rnelson0/puppet-generate-puppetfile/issues/25)

**Merged pull requests:**

- Release 1.0.0 [\#64](https://github.com/rnelson0/puppet-generate-puppetfile/pull/64) ([rnelson0](https://github.com/rnelson0))
- Process free-form repositories in a Puppetfile for fixtures [\#62](https://github.com/rnelson0/puppet-generate-puppetfile/pull/62) ([rnelson0](https://github.com/rnelson0))
- The forge module regex was not properly terminated by looking for end of line [\#61](https://github.com/rnelson0/puppet-generate-puppetfile/pull/61) ([rnelson0](https://github.com/rnelson0))
- Remove rubocop dependency [\#60](https://github.com/rnelson0/puppet-generate-puppetfile/pull/60) ([rnelson0](https://github.com/rnelson0))
- Update the forgeurl to use https [\#59](https://github.com/rnelson0/puppet-generate-puppetfile/pull/59) ([rnelson0](https://github.com/rnelson0))
- Format the Puppetfile into columns [\#57](https://github.com/rnelson0/puppet-generate-puppetfile/pull/57) ([binford2k](https://github.com/binford2k))

## [v0.11.0](https://github.com/rnelson0/puppet-generate-puppetfile/tree/v0.11.0) (2017-03-22)

[Full Changelog](https://github.com/rnelson0/puppet-generate-puppetfile/compare/0.10.0...v0.11.0)

**Closed issues:**

- accept 'forge' style module name as an argument [\#49](https://github.com/rnelson0/puppet-generate-puppetfile/issues/49)
- Features: Remove all comments [\#44](https://github.com/rnelson0/puppet-generate-puppetfile/issues/44)
- Bug: Incorrect dependency version [\#43](https://github.com/rnelson0/puppet-generate-puppetfile/issues/43)
- Add option to just generate a .fixtures file and not update the versions in the Modulefile [\#37](https://github.com/rnelson0/puppet-generate-puppetfile/issues/37)

**Merged pull requests:**

- Add --fixtures-only option to generate fixtures without performing updates [\#53](https://github.com/rnelson0/puppet-generate-puppetfile/pull/53) ([rnelson0](https://github.com/rnelson0))
- Add --ignore-comments flag [\#52](https://github.com/rnelson0/puppet-generate-puppetfile/pull/52) ([rnelson0](https://github.com/rnelson0))
- Add ability to reference module as author-name. [\#51](https://github.com/rnelson0/puppet-generate-puppetfile/pull/51) ([rnelson0](https://github.com/rnelson0))

## [0.10.0](https://github.com/rnelson0/puppet-generate-puppetfile/tree/0.10.0) (2016-11-06)

[Full Changelog](https://github.com/rnelson0/puppet-generate-puppetfile/compare/cbb9579b83d0f7ddefeb4de1e7b535177b67b481...0.10.0)

**Closed issues:**

- Fixtures: add symlinks to the fixtures [\#45](https://github.com/rnelson0/puppet-generate-puppetfile/issues/45)
- Generated Puppetfile missing quotes around module name [\#39](https://github.com/rnelson0/puppet-generate-puppetfile/issues/39)
- Detect renamed/expired forge modules when possible. [\#31](https://github.com/rnelson0/puppet-generate-puppetfile/issues/31)
- Specify required version of ruby 2.0.0, or find a workaround for mkmf. [\#30](https://github.com/rnelson0/puppet-generate-puppetfile/issues/30)
- Add support for 'mirroring' a Puppetfile into a .fixtures.yaml file [\#29](https://github.com/rnelson0/puppet-generate-puppetfile/issues/29)
- Add Windows support [\#28](https://github.com/rnelson0/puppet-generate-puppetfile/issues/28)
- Ensure there is a graceful failure when puppet is not available. [\#22](https://github.com/rnelson0/puppet-generate-puppetfile/issues/22)
- Is it not working?  [\#21](https://github.com/rnelson0/puppet-generate-puppetfile/issues/21)
- Filter comments in Puppetfile better [\#20](https://github.com/rnelson0/puppet-generate-puppetfile/issues/20)
- Feature: Check for puppet binary [\#19](https://github.com/rnelson0/puppet-generate-puppetfile/issues/19)
- Is this a recursive lookup? [\#18](https://github.com/rnelson0/puppet-generate-puppetfile/issues/18)
- Fixtures should use `source` not `project\_page` [\#16](https://github.com/rnelson0/puppet-generate-puppetfile/issues/16)
- Error check module downloads [\#12](https://github.com/rnelson0/puppet-generate-puppetfile/issues/12)
- Add --silent flag [\#11](https://github.com/rnelson0/puppet-generate-puppetfile/issues/11)
- mktemp message on OS X [\#9](https://github.com/rnelson0/puppet-generate-puppetfile/issues/9)
- Generate .fixtures.yml at the same time [\#1](https://github.com/rnelson0/puppet-generate-puppetfile/issues/1)

**Merged pull requests:**

- Release 0.10.0 [\#47](https://github.com/rnelson0/puppet-generate-puppetfile/pull/47) ([rnelson0](https://github.com/rnelson0))
- Fixtures symlink [\#46](https://github.com/rnelson0/puppet-generate-puppetfile/pull/46) ([rnelson0](https://github.com/rnelson0))
- Release 0.9.11 [\#42](https://github.com/rnelson0/puppet-generate-puppetfile/pull/42) ([rnelson0](https://github.com/rnelson0))
- Add ability to continue on download error [\#41](https://github.com/rnelson0/puppet-generate-puppetfile/pull/41) ([rnelson0](https://github.com/rnelson0))
- \(GH39\) Ensure module names have single quotes around it. [\#40](https://github.com/rnelson0/puppet-generate-puppetfile/pull/40) ([rnelson0](https://github.com/rnelson0))
- \(GH31\) Detect renamed/expired forge modules when possible. [\#38](https://github.com/rnelson0/puppet-generate-puppetfile/pull/38) ([rnelson0](https://github.com/rnelson0))
- \(GH29\) Add support for 'mirroring' a Puppetfile into a .fixtures.yaml file [\#36](https://github.com/rnelson0/puppet-generate-puppetfile/pull/36) ([rnelson0](https://github.com/rnelson0))
- Windows [\#35](https://github.com/rnelson0/puppet-generate-puppetfile/pull/35) ([rnelson0](https://github.com/rnelson0))
- Require Ruby 2.0.0 due to mkmf methods that are not present in stdlib \<2.0.0. [\#33](https://github.com/rnelson0/puppet-generate-puppetfile/pull/33) ([rnelson0](https://github.com/rnelson0))
- Improved tests [\#32](https://github.com/rnelson0/puppet-generate-puppetfile/pull/32) ([rnelson0](https://github.com/rnelson0))
- Rubocop [\#27](https://github.com/rnelson0/puppet-generate-puppetfile/pull/27) ([jyaworski](https://github.com/jyaworski))
- v0.9.8: Validate PMT properly downloads the specified module name. [\#24](https://github.com/rnelson0/puppet-generate-puppetfile/pull/24) ([rnelson0](https://github.com/rnelson0))
- Version 0.9.7 [\#23](https://github.com/rnelson0/puppet-generate-puppetfile/pull/23) ([rnelson0](https://github.com/rnelson0))
- \(GH16\)  Fixtures should use `source` not `project\_page` [\#17](https://github.com/rnelson0/puppet-generate-puppetfile/pull/17) ([rnelson0](https://github.com/rnelson0))
- Fixtures [\#15](https://github.com/rnelson0/puppet-generate-puppetfile/pull/15) ([rnelson0](https://github.com/rnelson0))
- Tickets/11 [\#14](https://github.com/rnelson0/puppet-generate-puppetfile/pull/14) ([rnelson0](https://github.com/rnelson0))
- Refactor the program into a few more discreet chunks for easier feature modification in the future. [\#13](https://github.com/rnelson0/puppet-generate-puppetfile/pull/13) ([rnelson0](https://github.com/rnelson0))
- Tickets/9 [\#10](https://github.com/rnelson0/puppet-generate-puppetfile/pull/10) ([rnelson0](https://github.com/rnelson0))
- Bump to v0.9.2 [\#8](https://github.com/rnelson0/puppet-generate-puppetfile/pull/8) ([rnelson0](https://github.com/rnelson0))
- Rubygem [\#7](https://github.com/rnelson0/puppet-generate-puppetfile/pull/7) ([rnelson0](https://github.com/rnelson0))
- Shuffled the bits to make this run [\#6](https://github.com/rnelson0/puppet-generate-puppetfile/pull/6) ([binford2k](https://github.com/binford2k))
- Improvements [\#5](https://github.com/rnelson0/puppet-generate-puppetfile/pull/5) ([rnelson0](https://github.com/rnelson0))
- Changed style [\#4](https://github.com/rnelson0/puppet-generate-puppetfile/pull/4) ([rnelson0](https://github.com/rnelson0))
- Fixes two bugs: [\#3](https://github.com/rnelson0/puppet-generate-puppetfile/pull/3) ([rnelson0](https://github.com/rnelson0))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
