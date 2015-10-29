# The CocoaPods check command.

# The CocoaPods namespace
module Pod
  class Command
    class Check < Command
      self.summary = <<-SUMMARY
          Displays which Pods would be changed by running `pod install`
      SUMMARY

      self.description = <<-DESC
          Compares the Pod lockfile with the manifest lockfile and shows
          any differences. In non-verbose mode, '~' indicates an existing Pod
          will be updated to the version specified in Podfile.lock, '+'
          indicates a missing Pod will be installed, and 'Δ' indicates a Pod
          is a development Pod. Development Pods are always considered
          to need installation.
      DESC

      self.arguments = []

      def self.options
        [
          ['--verbose', 'Show change details.']
        ].concat(super)
      end

      def initialize(argv)
        @check_command_verbose = argv.flag?('verbose')
        super
      end

      def run
        unless config.lockfile
          raise Informative, 'Missing Podfile.lock!'
        end

        development_pods = find_development_pods(config.podfile)
        results = find_differences(config, development_pods)
        print_results(results)
      end

      def find_development_pods(podfile)
        development_pods = {}
        podfile.dependencies.each do |dependency|
          development_pods[dependency.name] = dependency.external_source if dependency.external?
        end
        development_pods
      end

      def find_differences(config, development_pods)
        all_pod_names = config.lockfile.pod_names
        all_pod_names.concat development_pods.keys

        all_pod_names.sort.uniq.map do |spec_name|
          locked_version = config.lockfile.version(spec_name)

          # If no manifest, assume Pod hasn't been installed
          if config.sandbox.manifest
            manifest_version = config.sandbox.manifest.version(spec_name)
          else
            manifest_version = nil
          end

          # If this is a development Pod
          if development_pods[spec_name] != nil
            development_result(spec_name, development_pods[spec_name])

          # If this Pod is installed
          elsif manifest_version
            if locked_version != manifest_version
              changed_result(spec_name, manifest_version, locked_version)
            end

          # If this Pod is not installed
          else
            added_result(spec_name)
          end
        end.compact
      end

      def development_result(spec_name, external_source)
        if @check_command_verbose
          "#{spec_name} #{external_source}"
        else
          "Δ#{spec_name}"
        end
      end

      def changed_result(spec_name, manifest_version, locked_version)
        if @check_command_verbose
          "#{spec_name} #{manifest_version} -> #{locked_version}"
        else
          "~#{spec_name}"
        end
      end

      def added_result(spec_name)
        if @check_command_verbose
          "#{spec_name} newly added"
        else
          "+#{spec_name}"
        end
      end

      def print_results(results)
        return UI.puts "The Podfile's dependencies are satisfied" if results.empty?

        if @check_command_verbose
          UI.puts results.join("\n")
        else
          UI.puts results.join(', ')
        end

        raise Informative, "`pod install` will install #{results.length} Pod#{'s' if results.length > 1}."
      end
    end
  end
end
