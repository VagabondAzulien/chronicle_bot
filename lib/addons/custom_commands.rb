# frozen_string_literal: true

# Custom Commands: Add custom "echo" commands, to post a text message
#
# For example, "!hello" might print:
#   "Welcome to the channel! You can follow [this link](link) to visit
#   our website!"
require 'active_record'
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

        @bot.available_commands(self, list_commands)
      end

      # Provide help for the commands of this addon
      #
      # @param message [Message object] The relevant message object
      def help_command(message)
        pfx = @bot.cmd_prefix
        cmd = message.content[:body].split(/\s+/)[1].gsub(/#{pfx}/, '')

        case cmd
        when "addcommand"
          cmd_add_usage
        when "modcommand"
          cmd_mod_usage
        when "remcommand"
          cmd_rem_usage
        else
          cmd_custom_usage(cmd)
        end
      end

      # Handle a command from the Matrix protocol
      #
      # @param message [Message object] The relevant message object
      def matrix_command(message)
        pfx = @bot.cmd_prefix
        roomid = message.room_id
        cmd = message.content[:body].split(/\s+/)[0].gsub(/#{pfx}/, '')
        msgstr = message.content[:body]
                        .gsub(/#{pfx}\w+\s*/, '')
                        .strip

        res = 'Invalid command'

        case cmd
        when "addcommand"
          res = handle_addcommand(roomid, msgstr)
        when "modcommand"
          res = handle_modcommand(roomid, msgstr)
        when "remcommand"
          res = handle_remcommand(roomid, msgstr)
        else
          res = handle_runcommand(roomid, cmd)
        end

        room = @bot.client.ensure_room(roomid)

        room.send_notice(res)
      end

      # Adds a new custom command
      #
      # @param roomid [string] The Matrix Room ID
      # @param message [String] The command plus response
      # @return A response message
      def handle_addcommand(roomid, message)
        res = cmd_add_usage

        if message.split(/\s+/).count > 1
          command = message.slice!(/\w+\s+/).strip

          res = save_command(roomid, command, message)

          @bot.available_commands(self, [command])
        end

        res
      end

      # Modify an existing custom command
      #
      # @param roomid [string] The Matrix Room ID
      # @param message [hash] The message data from Matrix
      # @return A response message
      def handle_modcommand(roomid, message)
        res = cmd_add_usage

        if message.split(/\s+/).count > 1
          command = message.slice!(/\w+\s+/).strip

          res = mod_command(roomid, command, message)

          @bot.available_commands(self, [command])
        end

        res
      end

      # Remove an existing custom command
      #
      # @param roomid [string] The Matrix Room ID
      # @param message [hash] The message data from Matrix
      # @return A response message
      def handle_remcommand(roomid, message)
        res = cmd_rem_usage

        if message.split(/\s+/).count == 1
          command = message.strip

          res = remove_command(roomid, command)

          @bot.disable_commands(command)
        end

        res
      end

      # Return the response for a custom command
      #
      # @param roomid [string] The Matrix Room ID
      # @param message [hash] The message data from Matrix
      # @return A response message
      def handle_runcommand(roomid, message)
        res = cmd_rem_usage

        res = CustomCommands.find_by(
          roomid: roomid,
          command: message.strip
        ).response

        res
      end

      private

      # Check if a custom command conflicts with an existing addon command
      def addon_command(command)
        @bot.all_commands.keys.include?(command)
      end

      # Help message for addcommand
      def cmd_add_usage
        'Add a custom command. '\
        "\nUsage: !addcommand COMMAND TEXT"
      end

      # Help message for modcommand
      def cmd_custom_usage(cmd)
        'Prints text associated with the custom command'\
        "\nUsage: !#{cmd}"
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

      # Help message for modcommand
      def cmd_mod_usage
        'Modify a custom command. '\
        "\nUsage: !modcommand EXISTING-COMMAND TEXT"
      end

      # Error message when trying to delete a non-existing command
      def cmd_rem_error
        'This custom command does not exist. '\
        'Nothing to remove.'
      end

      # Help message for modcommand
      def cmd_rem_usage
        'Remove a custom command. '\
        "\nUsage: !remcommand EXISTING-COMMAND"
      end

      # List all available commands from the DB
      def list_commands
        commands = CustomCommands.select(:command).map do |c|
          c.command
        end

        commands
      end

      # Modify an existing command in the DB
      def mod_command(roomid, command, response)
        res = "Command updated: !#{command}"

        cc = CustomCommands.find_by(:command => command)
        cc.response = response

        unless cc.save
          @bot.scribe.info('CustomCommander') {
            "Problem modifying: #{command}. Not saved." 
          }

          return cc.errors.objects.first.full_message
        end
        
        @bot.scribe.info('CustomCommander') {
          "Custom command updated: #{command}"
        }

        res
      end

      # Remove an existing command from the DB
      def remove_command(roomid, command)
        res = "Command removed: !#{command}"

        CustomCommands.find_by(
          roomid: roomid,
          command: command
        ).delete

        res
      end

      # Save a new command to the DB
      def save_command(roomid, command, response)
        res = "Command saved: !#{command}"

        cc = CustomCommands.new do |c|
          c.roomid = roomid
          c.command = command
          c.response = response
        end

        unless cc.save
          @bot.scribe.info('CustomCommander') {
            "Duplicate command: #{command}. Not saved." 
          }

          return cc.errors.objects.first.full_message
        end
        
        @bot.scribe.info('CustomCommander') {
          "Custom command saved: #{command}"
        }

        res
      end
    end

    # The ActiveRecord model for handling the custom commands
    class CustomCommands < ActiveRecord::Base
      validates_presence_of :roomid, :command, :response
      validates_length_of :command, { minimum: 1 }
      validates_length_of :response, { minimum: 1 }

      validates :command, uniqueness: { message:
        "already exists. You can modify it by typing `!modcommand %{value}`"
      }
    end
  end
end
