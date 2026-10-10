# frozen_string_literal: true

require "pathname"
require "rubygems/command"

class Gem::Commands::TtagsCommand < Gem::Command
  def initialize
    super "ttags", "Generate ttags for gems"
  end

  def execute
    Gem::Specification.each { |spec| self.class.index(spec, ui) }
  end

  class << self
    def invoke(tag_file, *paths) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      write_error = nil
      begin
        command = ["ttags", "-f", tag_file.to_s, "--null", "--files-from", "-"]
        IO.popen(command, "wb") do |input|
          write_paths(input, paths)
        end
      rescue Errno::EPIPE => e
        # The child may reject the options before it reads the entire file list.
        write_error = e
      end

      check_status($?)
      raise write_error if write_error

      true
    end

    def can_write?(path)
      path.dirname.directory? && !path.directory? &&
        !(path.file? && path.read(1) == "!")
    end

    def index(spec, ui = nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      gem_path = Pathname.new(spec.full_gem_path)
      tagging_error = nil

      tag_file = gem_path.join("tags")
      paths = Dir.glob(gem_path.join("**/*.rb"))
      if paths.any? && can_write?(tag_file)
        ui&.say "Generating ttags for #{spec.full_name}"
        begin
          invoke(tag_file, *paths)
        rescue StandardError => e
          tagging_error = e
        end
      end

      inject(gem_path, spec, ui)
      raise tagging_error if tagging_error
    rescue StandardError => e
      raise unless ui

      ui.say "Failed making tags for #{spec.full_name}:\n  (#{e.class}) #{e}"
    end

    private

    def write_paths(input, paths)
      input.sync = true
      base = Pathname.pwd
      paths.each do |path|
        input.write("#{Pathname.new(path).relative_path_from(base)}\0")
      end
    end

    def check_status(status)
      return if status.success?

      reason = status.signaled? ? "signal #{status.termsig}" :
        "exit status #{status.exitstatus}"
      raise "ttags failed (#{reason}); " \
        "a build supporting --files-from and --null is required"
    end

    def inject(gem_path, spec, ui)
      target = gem_path.join("lib/bundler/cli.rb")
      return unless target.writable? && !target.read.include?("load_plugins")

      ui&.say "Injecting gem-ttags into #{spec.full_name}"
      target.open("a") do |f|
        f.write "\nGem.load_plugins rescue nil\n"
      end
    end
  end
end
