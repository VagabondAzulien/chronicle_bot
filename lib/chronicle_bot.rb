# frozen_string_literal: true

require 'faraday'
require 'json'
require 'matrix_sdk'

# Require any addons
Dir[File.join(__dir__, 'addons', '*.rb')].each do |file|
  require file
end

# Chronicle Bot
module Chronicle
  # A filter to simplify syncs
  BOT_FILTER = {
    presence: { types: [] },
    account_data: { types: [] },
    room: {
      ephemeral: { types: [] },
      state: {
        types: ['m.room.*'],
        lazy_load_members: true
      },
      timeline: {
        types: ['m.room.message']
      },
      account_data: { types: [] }
    }
  }.freeze

  # Chronicle Bot for Matrix
  module Matrix
    # Begin the beast
    def self.start(args)
      unless args.length >= 2
        raise "Usage: #{$PROGRAM_NAME} [-d] homeserver_url access_token"
      end

      if args.first == '-d'
        Thread.abort_on_exception = true
        MatrixSdk.debug!
        args.shift
      end

      bot = ChronicleBot.new args[0], args[1]
      bot.run
    end

    # The bot
    class ChronicleBot
      attr_reader :all_commands, :cmd_prefix

      def initialize(hs_url, access_token)
        @hs_url = hs_url
        @token = access_token

        @cmd_prefix = '!'
        @all_commands = {}
        @allowed_commands = {}

        register_commands
        available_commands(self, ['listcommands', 'help'])
      end

      # All available commands
      def available_commands(addon, commands)
        commands.each do |command|
          @all_commands[command] = addon
        end
      end

      def client
        @client ||= MatrixSdk::Client.new(
          @hs_url,
          access_token: @token,
          client_cache: :all
        )
      end

      def deep_copy(hash)
        Marshal.load(Marshal.dump(hash))
      end

      def disable_commands(*commands)
        commands.each do |command|
          @all_commands.delete(command)
        end
      end

      def help_command(message)
        pfx = @cmd_prefix
        cmd = message.content[:body].split(/\s+/)[1].gsub(/#{pfx}/, '')

        case cmd
        when 'listcommands'
          res = '!listcommands: List available commands managed by this bot'
        else
          res = 'Try !listcommands or !help'
        end

        res
      end

      # Handle a command from the Matrix protocol
      #
      # @param message [Message object] The relevant message object
      def matrix_command(message)
        pfx = @cmd_prefix
        cmd = message.content[:body].split(/\s+/)[0].gsub(/#{pfx}/, '')

        res = 'Invalid command'

        case cmd
        when 'listcommands'
          res = 'Currently available commands: '
          res += @all_commands.keys.join(', ')
        when 'help'
          res = if message.content[:body].split(/\s+/).count <= 1
                  '!help: Get help for a specific command' \
                  "\nUsage: !help COMMAND"
                else
                  second_cmd = message.content[:body].split(/\s+/)[1].gsub(/#{pfx}/, '')
                  res = @all_commands[second_cmd.strip].help_command(message)
                end
        end

        room = @client.ensure_room(message.room_id)
        room.send_notice(res)
      end

      def on_message(message)
        return unless message.content[:msgtype] == 'm.text'

        msgstr = message.content[:body]
        roomid = message.room_id
        cmds = @all_commands.keys.join('|')

        return unless msgstr =~ /^#{@cmd_prefix}#{cmds}\s*/

        msgstr.match(/^#{@cmd_prefix}(#{cmds})\s*/) do |m|
          @all_commands[m.to_s[1..-1].strip].matrix_command(message)
        end
      end

      def register_commands
        Chronicle::Addon.constants.each do |addon|
          cmd = Object.const_get("Chronicle::Addon::#{addon.to_s}")

          if cmd.methods.include?(:register)
            instance, commands = cmd.send(:register, self)

            available_commands(instance, commands)
          end
        end
      end

      # Run Chronicle
      def run
        # Join all invited rooms
        client.on_invite_event.add_handler { |ev| client.join_room(ev[:room_id]) }

        # Run an empty sync to get to a `since` token without old data.
        # Storing the `since` token is also valid for bot use-cases, but in the
        # case of ping responses there's never any need to reply to old data.
        empty_sync = deep_copy(BOT_FILTER)
        empty_sync[:room].map { |_k, v| v[:types] = [] }
        client.sync filter: empty_sync

        # Read all message events
        client.on_event.add_handler('m.room.message') { |ev| on_message(ev) }

        loop do
          begin
            client.sync filter: BOT_FILTER
          rescue MatrixSdk::MatrixError => e
            puts e
          end
        end
      end
    end
  end
end
