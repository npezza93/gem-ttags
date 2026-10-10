# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "rbconfig"
require "tmpdir"
require "rubygems/commands/ttags_command"

class TtagsCommandTest < Minitest::Test
  Command = Gem::Commands::TtagsCommand
  Spec = Struct.new(:full_gem_path, :full_name)
  UI = Struct.new(:messages) do
    def say(message)
      messages << message
    end
  end

  def setup
    @directory = Dir.mktmpdir("gem-ttags-test")
    @bin = File.join(@directory, "bin")
    FileUtils.mkdir_p(@bin)
    @record = File.join(@directory, "invocation")
    @old_path = ENV["PATH"]
    @old_record = ENV["GEM_TTAGS_TEST_RECORD"]
    ENV["PATH"] = [@bin, @old_path].compact.join(File::PATH_SEPARATOR)
    ENV["GEM_TTAGS_TEST_RECORD"] = @record
    fake_ttags
  end

  def teardown
    ENV["PATH"] = @old_path
    ENV["GEM_TTAGS_TEST_RECORD"] = @old_record
    FileUtils.remove_entry(@directory)
  end

  def test_streams_nul_separated_relative_paths_without_shell_expansion
    names = ["ordinary.rb", "space name.rb", "line\nbreak.rb", "-option.rb",
             "quote'\".rb", "$(touch INJECTED).rb", "semi;colon.rb", "日本語.rb"]
    paths = names.map { |name| File.join(@directory, name) }
    tag_file = File.join(@directory, "tags with spaces;literal")

    Dir.chdir(@directory) { assert Command.invoke(tag_file, *paths) }

    argv, input = invocation
    assert_equal ["-f", tag_file, "--null", "--files-from", "-"], argv
    assert_equal names.join("\0") + "\0", input
    refute_path_exists File.join(@directory, "INJECTED")
  end

  def test_streams_file_list_larger_than_command_line_limits
    paths = large_paths
    expected = paths.map do |path|
      Pathname.new(path).relative_path_from(Pathname.pwd).to_s
    end

    assert Command.invoke(File.join(@directory, "tags"), *paths)

    argv, input = invocation
    assert_equal 5, argv.length
    assert_operator input.bytesize, :>, 4 * 1024 * 1024
    assert_equal expected, input.split("\0")
  end

  def test_empty_input_is_closed_and_child_is_waited_for
    assert Command.invoke(File.join(@directory, "tags"))

    assert_equal "", invocation.last
    assert $?.success?
  end

  def test_child_failure_is_reported
    fake_ttags("STDIN.read\nexit 7\n")

    error = assert_raises(RuntimeError) { Command.invoke("tags") }

    assert_match "exit status 7", error.message
  end

  def test_old_ttags_rejecting_options_reports_status_instead_of_broken_pipe
    fake_ttags("exit 2\n")

    error = assert_raises(RuntimeError) do
      Command.invoke("tags", *large_paths)
    end

    assert_match "exit status 2", error.message
    assert_match "--files-from and --null", error.message
    assert_equal 2, $?.exitstatus
  end

  def test_broken_pipe_is_not_success_even_if_child_exits_zero
    fake_ttags("exit 0\n")

    assert_raises(Errno::EPIPE) { Command.invoke("tags", *large_paths) }

    assert $?.success?
  end

  def test_signal_termination_is_reported
    fake_ttags("Process.kill(\"TERM\", Process.pid)\nsleep 10\n")

    error = assert_raises(RuntimeError) { Command.invoke("tags") }

    assert_match "signal #{Signal.list.fetch('TERM')}", error.message
  end

  def test_missing_executable_is_reported
    FileUtils.rm(File.join(@bin, "ttags"))
    ENV["PATH"] = @bin

    assert_raises(Errno::ENOENT) { Command.invoke("tags") }
  end

  def test_index_includes_nested_engine_ruby_files_only
    spec = gem_spec
    expected = ["lib/top.rb", "engines/nested/app/model.rb"].map do |path|
      write_file(File.join(spec.full_gem_path, path), "class Example; end\n")
    end
    write_file(File.join(spec.full_gem_path, "README.md"), "ignored")
    ui = UI.new([])

    Command.index(spec, ui)

    argv, input = invocation
    assert_equal File.join(spec.full_gem_path, "tags"), argv[1]
    actual = input.split("\0").map { |path| File.expand_path(path) }
    assert_equal expected.sort, actual.sort
    assert_equal ["Generating ttags for sample-1.0"], ui.messages
  end

  def test_index_skips_gems_without_ruby_files
    Command.index(gem_spec)

    refute_path_exists @record
  end

  def test_index_preserves_existing_ctags_file
    spec = gem_spec
    write_file(File.join(spec.full_gem_path, "lib/example.rb"), "class Example; end\n")
    tag_file = write_file(File.join(spec.full_gem_path, "tags"), "!_TAG_FILE_FORMAT\t2\n")

    Command.index(spec)

    refute_path_exists @record
    assert_equal "!_TAG_FILE_FORMAT\t2\n", File.read(tag_file)
  end

  def test_index_does_not_write_over_a_tags_directory
    spec = gem_spec
    write_file(File.join(spec.full_gem_path, "lib/example.rb"), "class Example; end\n")
    FileUtils.mkdir_p(File.join(spec.full_gem_path, "tags"))

    Command.index(spec)

    refute_path_exists @record
  end

  def test_index_reports_failure_to_the_ui
    spec = gem_spec
    write_file(File.join(spec.full_gem_path, "lib/example.rb"), "class Example; end\n")
    fake_ttags("STDIN.read\nexit 3\n")
    ui = UI.new([])

    Command.index(spec, ui)

    assert_match "Failed making tags for sample-1.0", ui.messages.last
    assert_match "exit status 3", ui.messages.last
  end

  def test_index_raises_failure_without_a_ui
    spec = gem_spec
    write_file(File.join(spec.full_gem_path, "lib/example.rb"), "class Example; end\n")
    fake_ttags("STDIN.read\nexit 3\n")

    assert_raises(RuntimeError) { Command.index(spec) }
  end

  def test_bundler_plugin_injection_is_idempotent
    spec = gem_spec
    target = write_file(File.join(spec.full_gem_path, "lib/bundler/cli.rb"), "# bundler\n")

    2.times { Command.index(spec) }

    assert_equal 1, File.read(target).scan("Gem.load_plugins rescue nil").length
  end

  def test_bundler_plugin_injection_still_runs_when_tagging_fails
    spec = gem_spec
    target = write_file(File.join(spec.full_gem_path, "lib/bundler/cli.rb"), "# bundler\n")
    fake_ttags("STDIN.read\nexit 3\n")
    ui = UI.new([])

    2.times { Command.index(spec, ui) }

    assert_equal 1, File.read(target).scan("Gem.load_plugins rescue nil").length
    assert_match "exit status 3", ui.messages.last
  end

  def test_real_ttags_produces_the_same_tags_as_positional_paths
    executable = ENV["TTAGS"]
    skip "Set TTAGS to a compatible ttags executable for integration coverage" unless executable

    executable = File.expand_path(executable)
    FileUtils.rm(File.join(@bin, "ttags"))
    FileUtils.ln_s(executable, File.join(@bin, "ttags"))
    names = ["one.rb", "space name.rb", "line\nbreak.rb", "-dash.rb", "日本語.rb"]
    paths = names.each_with_index.map do |name, i|
      write_file(File.join(@directory, name), "class Example#{i}; def call; end; end\n")
    end
    tag_file = File.join(@directory, "tags")
    assert system(executable, "-f", tag_file, *paths)
    expected = File.binread(tag_file)

    Dir.chdir(@directory) { assert Command.invoke(tag_file, *paths) }

    assert_equal expected, File.binread(tag_file)
    names.length.times { |i| assert_includes expected, "Example#{i}\t" }
  end

  private

  def fake_ttags(body = nil)
    body ||= 'File.binwrite(ENV.fetch("GEM_TTAGS_TEST_RECORD"), Marshal.dump([ARGV, STDIN.read]))'
    file = write_file(File.join(@bin, "ttags"), "#!#{RbConfig.ruby}\n#{body}\n")
    File.chmod(0o755, file)
  end

  def invocation
    Marshal.load(File.binread(@record))
  end

  def large_paths
    Array.new(24_000) { |i| File.join(@directory, "#{'x' * 200}#{i}.rb") }
  end

  def gem_spec
    path = File.join(@directory, "sample gem-1.0")
    FileUtils.mkdir_p(path)
    Spec.new(path, "sample-1.0")
  end

  def write_file(path, contents)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, contents)
    path
  end
end
