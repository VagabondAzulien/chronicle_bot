# frozen_string_literal: true

# Custom Commands: Add custom "echo" commands, to post a text message
#
# For example, "!hello" might print:
#   "Welcome to the channel! You can follow [this link](link) to visit
#   our website!"
require 'json'

module Chronicle
  module Addon
    class CustomCommander
      def self.register(bot)
        addon_instance = new(bot)
        addon_command = ['addcommand','modcommand','remcommand']

        [addon_instance, addon_command]
      end

      def initialize(bot)
        @bot = bot
        @msgid = 'tmp_until_per-room'
        @custom_commands = read_commands(@msgid)

        @bot.available_commands(self, @custom_commands.keys)
      end

      # Handle a command from the Matrix protocol
      #
      # @param message [Message object] The relevant message object
      def matrix_command(message)
        pfx = @bot.cmd_prefix
        cmd = message.content[:body].split(/\s+/)[0].gsub(/#{pfx}/, '')
        msgstr = message.content[:body]
                        .gsub(/#{pfx}\w+\s*/, '')
                        .strip

        res = 'Invalid command'

        case cmd
        when "addcommand"
          res = handle_addcommand(msgstr)
        when "modcommand"
          res = handle_modcommand(msgstr)
        when "remcommand"
          res = handle_remcommand(msgstr)
        else
          res = runcmd(cmd)
        end

        room = @bot.client.ensure_room(message.room_id)

        room.send_notice(res)
      end

      # Add a new custom command
      def addcmd(message)
        command = message.slice!(/\w+\s+/).strip

        return cmd_add_error(command) if verify_commands(command)
        return cmd_addon_error if addon_command(command)

        @custom_commands[command] = message
        @bot.available_commands(self, [command])
        save_commands(@msgid)

        "New command saved: !#{command}"
      end

      # Adds a new custom command
      #
      # @param message [String] The command plus response
      # @return 
      def handle_addcommand(message)
        res = 'Usage: !addcommand NAME RESPONSE'

        if message.split(/\s+/).count > 1
          res = addcmd(message)
        end

        res
      end

      # Modify an existing custom command
      #
      # @param message [hash] The message data from Matrix
      def handle_modcommand(message)
        res = 'Usage: !modcommand NAME NEW-RESPONSE'

        if message.split(/\s+/).count > 1
          res = modcmd(message)
        end

        res
      end

      # Remove an existing custom command
      #
      # @param message [hash] The message data from Matrix
      def handle_remcommand(message)
        res = 'Usage: !remcommand NAME'

        if message.split(/\s+/).count == 1
          res = remcmd(message)
        end

        res
      end

      # Modify an existing custom command
      def modcmd(message)
        command = message.slice!(/\w+\s+/).strip

        return cmd_mod_error(command) unless verify_commands(command)

        @custom_commands[command] = message
        save_commands(@msgid)

        "!#{command} modified."
      end

      # Delete an existing custom command
      def remcmd(message)
        command = message.strip

        return cmd_rem_error unless verify_commands(command)

        @custom_commands.delete(command)
        @bot.disable_commands(command)
        save_commands(@msgid)

        "!#{command} removed."
      end

      # Execute a custom command
      def runcmd(command)
        return cmd_mod_error(command) unless verify_commands(command)

        @custom_commands[command]
      end

      private

      # Check if a custom command conflicts with an existing addon command
      def addon_command(command)
        @bot.all_commands.keys.include?(command)
      end

      # Error message when trying to add an existing command
      def cmd_add_error(command)
        'This custom command already exists. '\
        "You can modify it by typing `!modcommand #{command}`"
      end

      # Error message when trying to add an existing command
      def cmd_addon_error
        'This command is already used by another addon.'
      end

      # Error message when trying to modify a non-existing command
      def cmd_mod_error(command)
        'This custom command does not exist. '\
        "You can add it by typing `!addcommand #{command}`"
      end

      # Error message when trying to delete a non-existing command
      def cmd_rem_error
        'This custom command does not exist. '\
        'Nothing to remove.'
      end

      # Read the existing saved commands into memory
      def read_commands(msgid)
        cmds = {}
        cmds_file = "#{msgid}_custom_commands.json"

        if File.exist?(cmds_file) && !File.empty?(cmds_file)
          File.open(cmds_file, 'r') do |f|
            cmds = JSON.parse(f.read)
          end
        end

        cmds
      end

      # Save the existing commands to a local file
      def save_commands(msgid)
        cmds_file = "#{msgid}_custom_commands.json"

        File.open(cmds_file, 'w') do |f|
          f.write(@custom_commands.to_json)
        end
      end

      # Check if a command already exists
      def verify_commands(command)
        @custom_commands.keys.include?(command)
      end
    end
  end
end
