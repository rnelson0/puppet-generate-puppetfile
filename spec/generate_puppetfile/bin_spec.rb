require 'spec_helper'
require 'rspec/mocks'
require 'optparse'

class CommandRun
  attr_accessor :stdout, :stderr, :exitstatus

  def initialize(args)
    out = StringIO.new
    err = StringIO.new

    $stdout = out
    $stderr = err

    @exitstatus = GeneratePuppetfile::Bin.new(args).run

    @stdout = out.string.strip
    @stderr = err.string.strip

    $stdout = STDOUT
    $stderr = STDERR
  end

end

def file_cleanup()
  [
    'Puppetfile',
    '.fixtures.yml',
  ].each do |tempfile|
    File.delete(tempfile) if File.exists?(tempfile)
  end
end

describe GeneratePuppetfile::Bin do
  subject do
    sane_args = if args.is_a? Array
                  args
                else
                  [args]
                end
    CommandRun.new(sane_args)
  end

  before(:all) do
    file_cleanup()
  end

  after(:all) do
    file_cleanup()
  end

  context 'with hyphens in module name' do
    let :args do
      'rnelson0-certs'
    end

    its(:exitstatus) { is_expected.to eq(0) }

    it 'should include the module name in single quotes' do
      expect(subject.stdout).to include "mod 'rnelson0/certs'"
    end
  end

  context 'when running with one module on the CLI' do
    let :args do
      'rnelson0/certs'
    end

    its(:exitstatus) { is_expected.to eq(0) }

    it 'should include the module name in single quotes' do
      expect(subject.stdout).to include "mod 'rnelson0/certs'"
    end
  end

  context 'when puppet is not available' do
    let :args do
      'rnelson0/certs'
    end

    its(:exitstatus) do
      expect(ENV).to receive(:[]).with('PATH').and_return('/dne')
      is_expected.to eq(1)
    end
  end

  context 'when specifying an invalid module name' do
    let :args do
      'certs'
    end

    its(:exitstatus) { is_expected.to eq(1) }
  end

  context 'when specifying a valid Puppetfile' do
    let :args do
      [
        '-p',
        'spec/Puppetfile.valid',
      ]
    end

    its(:exitstatus) { is_expected.to eq(0) }
    it 'should include comments in the result' do
      expect(subject.stdout).to include "# Comments"
    end
  end

  context 'when specifying a valid Puppetfile and --ignore-comments' do
    let :args do
      [
        '-p',
        'spec/Puppetfile.valid',
        '--ignore-comments',
      ]
    end

    its(:exitstatus) { is_expected.to eq(0) }
    it 'should not include comments in the result' do
      expect(subject.stdout).not_to include "# Comments"
    end
  end

  context 'when specifying a valid Puppetfile and an invalid module name' do
    let :args do
      [
        '-p',
        'spec/Puppetfile.valid',
        'certs',
      ]
    end

    its(:exitstatus) { is_expected.to eq(0) }
  end

  context 'when specifying a non-existing module name' do
    let :args do
      'rnelson0/12345'
    end

    its(:exitstatus) { is_expected.to eq(2) }
  end

  context 'when creating fixtures' do
    let :args do
      [
        'rnelson0/certs',
        '--create-fixtures',
      ]
    end

    file_cleanup()

    its(:exitstatus) { is_expected.to eq(0) }
    it 'should say that fixtures have been created' do
      expect(subject.stdout).to include "Generating .fixtures.yml"
    end
    it 'should create .fixtures.yml' do
      File.exists? './.fixtures.yml'
    end
  end

  context 'when specifying a valid Puppetfile and fixtures only' do
    let :args do
      [
        '-p',
        'spec/Puppetfile.valid',
        '--fixtures-only',
      ]
    end

    file_cleanup()

    its(:exitstatus) { is_expected.to eq(0) }
    it 'should say that fixtures have been created' do
      expect(subject.stdout).to include "Generating .fixtures.yml"
    end
    it 'should create .fixtures.yml' do
      File.exists? './.fixtures.yml'
    end
  end

  context 'when specifying a valid Puppetfile with non-forge modules and fixtures only' do
    let :args do
      [
        '-p',
        'spec/Puppetfile.complexfixtures',
        '--fixtures-only',
      ]
    end

    file_cleanup()
    its(:exitstatus) { is_expected.to eq(0) }
    it 'should say that fixtures have been created' do
      expect(subject.stdout).to include "Generating .fixtures.yml"
    end
    it 'should create .fixtures.yml' do
      File.exists? './.fixtures.yml'
    end
    it 'should add the non-forge modules to the fixtures' do
      fixture_data = <<EOF
  repositories:
    ntp:
      repo: "https://github.com/example-ntp.git"
      tag: "0.1.1"
    motd:
      repo: "https://github.com/example-motd.git"
      tag: "1.0.0"
EOF
      expect(File.read('./.fixtures.yml')).to include(fixture_data)
    end
  end

  context 'when a Puppetfile includes a non-forge module' do
    let :args do
      [
        '-p',
        'spec/Puppetfile.nonforge',
      ]
    end

    its(:exitstatus) { is_expected.to eq(0) }
  end
  
  context 'when specifying a valid Puppetfile with capitalization in the module name' do
    let :args do
      [
        '-p',
        'spec/Puppetfile.capitalized',
        '--fixtures-only',
      ]
    end

    file_cleanup()
    its(:exitstatus) { is_expected.to eq(0) }
    it 'should say that fixtures have been created' do
      expect(subject.stdout).to include "Generating .fixtures.yml"
    end
    it 'should create .fixtures.yml' do
      File.exists? './.fixtures.yml'
    end
    it 'should add the capitalized module to the fixtures' do
      expect(File.read('./.fixtures.yml')).to include('WhatsARanjit/node_manager')
    end
  end
end
