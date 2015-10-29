require 'cocoapods'
require_relative '../lib/pod/command/check'

describe Pod::Command::Check do
  it 'detects no differences' do
    check = Pod::Command::Check.new(CLAide::ARGV.new([]))

    config = create_config({ :pod_one => '1.0', :pod_two => '2.0' }, { :pod_one => '1.0', :pod_two => '2.0' })

    development_pods = {}
    results = check.find_differences(config, development_pods)

    expect(results).to eq([])
  end

  it 'detects modifications and additions' do
    check = Pod::Command::Check.new(CLAide::ARGV.new([]))

    config = create_config(
        {
            :pod_one => '1.0',
            :pod_two => '3.0',
            :pod_three => '2.0'
        },
        {
            :pod_one => '1.0',
            :pod_two => '2.0',
            :pod_three => nil
        }
    )

    development_pods = {}
    results = check.find_differences(config, development_pods)

    # Alphabetical order
    expect(results).to eq([ '+pod_three', '~pod_two' ])
  end

  it 'detects modifications and additions with verbosity' do
    check = Pod::Command::Check.new(CLAide::ARGV.new([ '--verbose' ]))

    config = create_config(
        {
            :pod_one => '1.0',
            :pod_two => '3.0',
            :pod_three => '2.0'
        },
        {
            :pod_one => '1.0',
            :pod_two => '2.0',
            :pod_three => nil
        }
    )

    development_pods = {}
    results = check.find_differences(config, development_pods)

    # Alphabetical order
    expect(results).to eq([ 'pod_three newly added', 'pod_two 2.0 -> 3.0' ])
  end

  it 'handles development pods' do
    check = Pod::Command::Check.new(CLAide::ARGV.new([]))

    config = create_config({ :pod_one => '1.0', :pod_two => nil }, { :pod_one => '1.0', :pod_two => nil })

    development_pods = { :pod_two => 'source' }
    results = check.find_differences(config, development_pods)

    expect(results).to eq([ 'Δpod_two' ])
  end

  it 'handles development pods with verbosity' do
    check = Pod::Command::Check.new(CLAide::ARGV.new([ '--verbose' ]))

    config = create_config({ :pod_one => '1.0', :pod_two => nil }, { :pod_one => '1.0', :pod_two => nil })

    development_pods = { :pod_two => 'source' }
    results = check.find_differences(config, development_pods)

    expect(results).to eq([ 'pod_two source' ])
  end

  def create_config(lockfile_hash, manifest_hash)
    config = Pod::Config.new
    lockfile = double('lockfile')
    sandbox = double('sandbox')
    manifest = double('manifest')

    allow(config).to receive(:lockfile).and_return(lockfile)
    allow(config).to receive(:sandbox).and_return(sandbox)
    allow(sandbox).to receive(:manifest).and_return(manifest)

    allow(lockfile).to receive(:pod_names).and_return(lockfile_hash.keys)
    lockfile_hash.each do |key, value|
      allow(lockfile).to receive(:version).with(key).and_return(value)
    end

    manifest_hash.each do |key, value|
      allow(manifest).to receive(:version).with(key).and_return(value)
    end

    config
  end
end
