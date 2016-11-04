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

describe GeneratePuppetfile::Bin do
  subject do
    sane_args = if args.is_a? Array
                  args
                else
                  [args]
                end
    CommandRun.new(sane_args)
  end

  after(:each) do
    [
      'Puppetfile',
      '.fixtures.yml',
    ].each do |tempfile|
      #File.delete(tempfile) if File.exists?(tempfile)
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

  context 'when specifying a bad module name' do
    let :args do
      'rnelson0/12345'
    end

    its(:exitstatus) { is_expected.to eq(2) }
  end

  context 'when creating fixtures' do
    let :args do [
        'rnelson0/certs',
        '--create-fixtures',
      ]
    end

    its(:exitstatus) { is_expected.to eq(0) }
    it 'should say that fixtures have been created' do
      expect(subject.stdout).to include "Generating .fixtures.yml"
    end
    it 'should create .fixtures.yml' do
      File.exists? './.fixtures.yml'
    end
  end
end
