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
    def invoke(tag_file, *paths)
      system(
        "ttags",
        "-f",
        tag_file.to_s,
        *paths.map { |p| Pathname.new(p).relative_path_from(Pathname.pwd).to_s }
      )
    end

    def can_write?(path)
      path.dirname.directory? && !path.directory? &&
        !(path.file? && path.read(1) == "!")
    end

    def index(spec, ui = nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      gem_path = Pathname.new(spec.full_gem_path)

      tag_file = gem_path.join("tags")
      paths = Dir.glob(gem_path.join("**/*.rb"))
      if paths.any? && can_write?(tag_file)
        ui&.say "Generating ttags for #{spec.full_name}"
        invoke(tag_file, *paths)
      end

      inject(gem_path, spec, ui)
    rescue StandardError => e
      raise unless ui

      ui.say "Failed making tags for #{spec.full_name}:\n  (#{e.class}) #{e}"
    end

    private

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
