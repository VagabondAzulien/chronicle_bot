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
  end
end
