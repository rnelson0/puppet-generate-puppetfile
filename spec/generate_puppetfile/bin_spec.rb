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

  context 'when running with one module on the CLI' do
    let :args do
      'rnelson0/certs'
    end

    its(:exitstatus) { is_expected.to eq(0) }
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

    its(:exitstatus) { is_expected.to eq(1) }
  end
end
