# frozen_string_literal: true

module Chronicle
  module Matrix
    # Ping - Pong. Useful for testing
    #
    # @param client [Client object] The current Matrix client connection
    # @param message [Message object] The relevant message object
    def handle_ping(client, message)
      room = client.ensure_room message.room_id

      room.send_notice('Pong!')
    end

    # 8-Ball: Give a random, vague response to a question
    #
    # @param client [Client object] The current Matrix client connection
    # @param message [Message object] The relevant message object
    def handle_8ball(client, message)
      msgstr = message.content[:body]
                      .gsub(/!8ball\s*/, '')
                      .strip

      room = client.ensure_room(message.room_id)

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
