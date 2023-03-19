# frozen_string_literal: true

require "rubygems/command_manager"
require "rubygems/commands/ttags_command"

Gem::CommandManager.instance.register_command :ttags

Gem.post_install do |installer|
  Gem::Commands::TtagsCommand.index(installer.spec, installer.ui)
end
