# frozen_string_literal: true

# Custom Commands: Add custom "echo" commands, to post a text message
#
# For example, "!hello" might print:
#   "Welcome to the channel! You can follow [this link](link) to visit
#   our website!"

module Chronicle
  module Matrix
    # Add addon-specific commands to the allowed commands array
    add_allowed_commands(%w[addcommand modcommand remcommand])

    # Add a custom command
    #
    # @param commander [CustomCommander instance] The CustomCommander to work
    #                  with
    # @param client [Matrix Client instance] The client to work with
    # @param message [hash] The message data from Matrix
    def handle_addcommand(client, message)
      msgstr = message.content[:body]
                      .gsub(/!addcommand\s*/, '')
                      .strip

      room = client.ensure_room(message.room_id)

      commander = CustomCmd.commanders(message)
      res = commander.addcmd(msgstr)

      room.send_notice(res)
    end

    # Modify an existing custom command
    #
    # @param message [hash] The message data from Matrix
    def handle_modcommand(client, message)
      msgstr = message.content[:body]
                      .gsub(/!modcommand\s*/, '')
                      .strip

      room = client.ensure_room(message.room_id)

      commander = CustomCmd.commanders(message)
      res = commander.modcmd(msgstr)

      room.send_notice(res)
    end

    # Remove an existing custom command
    #
    # @param message [hash] The message data from Matrix
    def handle_remcommand(client, message)
      msgstr = message.content[:body]
                      .gsub(/!remcommand\s*/, '')
                      .strip

      room = client.ensure_room(message.room_id)

      commander = CustomCmd.commanders(message)
      res = commander.remcmd(msgstr)

      room.send_notice(res)
    end

    module CustomCmd
      require 'json'

      @@commander_instances = {}

      def self.commanders(message)
        msgid = message.room_id

        unless @@commander_instances.keys.include?(msgid)
          @@commander_instances[msgid] = CustomCommander.new(msgid)
        end

        @@commander_instances[msgid]
      end

      class CustomCommander
        def initialize(msgid)
          # build custom commands DB in memory
          @msgid = msgid
          @custom_commands = read_commands(@msgid)
        end

        # Add a new custom command
        def addcmd(message)
          command = message.slice!(/\w+\s+/).strip

          return cmd_add_error(command) if verify_commands(command)
          
          @custom_commands[command] = message
          save_commands(@msgid)

          "New command saved: !#{command}"
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

          return cmd_rem_error(command) unless verify_commands(command)

          @custom_commands.delete(command)
          save_commands(@msgid)

          "!#{command} removed."
        end

        # Execute a custom command
        def runcmd(command)
          return cmd_mod_error(command) unless verify_commands(command)

          @custom_commands[command]
        end

        private

        # Error message when trying to add an existing command
        def cmd_add_error(command)
          "This command already exists. \
          You can modify it by typing `!modcommand #{command}`"
        end

        # Error message when trying to modify a non-existing command
        def cmd_mod_error(command)
          "This command does not exist. \
          You can add it by typing `!addcommand #{command}`"
        end

        # Error message when trying to delete a non-existing command
        def cmd_rem_error(command)
          "This command does not exist. \
          Nothing to remove."
        end

        # Read the existing saved commands into memory
        def read_commands(msgid)
          cmds = {}
          cmds_file = "#{msgid}_custom_commands.json"

          if File.exists?(cmds_file) && !File.empty?(cmds_file)
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
end
