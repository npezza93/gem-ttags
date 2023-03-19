# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "gem-ttags"
  spec.version = "1.0.1"
  spec.authors = ["Nick Pezza"]
  spec.email = ["pezza@hey.com"]

  spec.summary = %q(Automatic ttags generation on gem install)
  spec.homepage = "https://github.com/npezza93/gem-ttags"
  spec.license = "MIT"

  spec.require_path  = "lib"
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)/}) }
  end

  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "github_repo" => "ssh://github.com/npezza93/gem-ttags",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "https://github.com/npezza93/gem-ttags/releases",
  }

  spec.required_ruby_version = ">= 2.7.0"
end
