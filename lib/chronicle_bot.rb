# frozen_string_literal: true

require 'faraday'
require 'json'
require 'matrix_sdk'

# Chronicle Bot
module Chronicle
  # Require any addons
  Dir[File.join(__dir__, 'addons', '*.rb')].each do |file|
    require file
  end

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
    @@default_allowed_commands = %w[ping]
    @@room_allowed_commands = {}

    # Update allowed commands
    def add_allowed_commands(cmds, msgid='')
      if msgid
        @@room_allowed_commands[msgid].concat(cmds)
      else
        @@room_allowed_commands.each { |_,v| v.concat(cmds) }
      end
    end

    # Establish or return allowed commands for a room
    def allowed_commands(msgid)
      @@room_allowed_commands[msgid] ||= @@default_allowed_commands
    end

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
      include Matrix

      def initialize(hs_url, access_token)
        @hs_url = hs_url
        @token = access_token
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

      def on_message(message)
        return unless message.content[:msgtype] == 'm.text'

        msgstr = message.content[:body]
        msgid = message.room_id
        cmds = allowed_commands(msgid).join('|')

        return unless msgstr =~ /^!#{cmds}\s*/

        msgstr.match(/^!(#{cmds})\s*/) do |m| 
          send(
            "handle_#{m.to_s[1..-1].strip}",
            client,
            message
          )
        end
      end

      def client
        @client ||= MatrixSdk::Client.new(
          @hs_url,
          access_token: @token,
          client_cache: :none
        )
      end

      def deep_copy(hash)
        Marshal.load(Marshal.dump(hash))
      end
    end
  end
end
