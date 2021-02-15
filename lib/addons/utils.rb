# frozen_string_literal: true

module Chronicle
  module Addon
    # Ping - Pong. Useful for testing
    class Ping
      def self.register(bot)
        addon_instance = new(bot)
        addon_command = ['ping']

        [addon_instance, addon_command]
      end

      def initialize(bot)
        @bot = bot
      end

      # Handle a command from the Matrix protocol
      #
      # @param message [Message object] The relevant message object
      def matrix_command(message)
        room = @bot.client.ensure_room(message.room_id)

        room.send_notice('Pong!')
      end
    end

    # 8-Ball: Give a random, vague response to a question
    class Eightball
      def self.register(bot)
        addon_instance = new(bot)
        addon_command = ['8ball']

        [addon_instance, addon_command]
      end

      def initialize(bot)
        @bot = bot
      end

      # Handle a command from the Matrix protocol
      #
      # @param message [Message object] The relevant message object
      def matrix_command(message)
        msgstr = message.content[:body]
                        .gsub(/!8ball\s*/, '')
                        .strip

        room = @bot.client.ensure_room(message.room_id)

        fates = [
          'Resoundingly, yes.',
          'Chances are good.',
          'Signs point to yes.',
          'Wheel.',
          'It is worth the attempt.',
          'Uncertainty clouds my sight.',
          'Wheel and woe.',
          'Neither wheel nor woe.',
          'Concentrate, and ask again.',
          'I cannot say for sure.',
          'The fates do not know.',
          "Why are you asking me? I'm just a bot.",
          'Error: Fate API returned 404. Try again later.',
          'Woe.',
          'Chances are poor.',
          'Signs point to no.',
          'Very doubtful.',
          'Absolutely no.'
        ]

        res = if msgstr[-1] == '?'
                fates.sample
              else
                'You must ask a question. Try again'
              end

        room.send_notice(res)
      end
    end
  end
end
