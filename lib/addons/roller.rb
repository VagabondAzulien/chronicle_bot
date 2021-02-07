# frozen_string_literal: true

module Chronicle
  module Matrix
    # Roll dice and get the results
    #
    # @param message [hash] The message data from Matrix
    def handle_roll(client, message)
      msgstr = message.content[:body]
                      .gsub(/!roll\s*/, '')
                      .strip

      room = client.ensure_room(message.room_id)

      res = Roller.roll(msgstr)

      final_msg = res.reduce("") { |x,y| x+y+"\n" }

      room.send_notice(final_msg)
    end

    module Roller
      # Solve an arithmatic forumla from a string
      #
      # @param string [String] The string representation of the formula
      # @return Integer of the solution
      def self.solve(string)
        formatted = string.gsub(/\s+/, '')
        formatted = formatted.gsub(/\[[\d,]*\]/) do |a|
          a.scan(/\d*/).reduce(0) { |x, y| x + y.to_i }
        end

        if formatted.match(/\(.*\)/)
          formatted = formatted.sub(/\(.*\)/) do |m|
            solve(m[1..-2])
          end

          solve(formatted)

        elsif formatted.match(/\d+\*\d+/)
          formatted = formatted.sub(/\d+\*\d+/) do |m|
            m.split('*').reduce(1) { |x, y| x * y.to_i }
          end

          solve(formatted)

        elsif formatted.match(/\d+\/\d+/)
          formatted = formatted.sub(/\d*\/\d*/) do |m|
            m.split('/').reduce { |x, y| x.to_i / y.to_i }
          end

          solve(formatted)

        elsif formatted.match(/\d+\+\d+/)
          formatted = formatted.sub(/\d+\+\d+/) do |m|
            m.split('+').reduce(0) { |x, y| x + y.to_i }
          end

          solve(formatted)

        elsif formatted.match(/\d+\-\d+/)
          formatted = formatted.sub(/\d+\-\d+/) do |m|
            m.split('-').reduce { |x, y| x.to_i + -(y.to_i) }
          end

          solve(formatted)

        else
          formatted.to_i
        end
      end

      # Pretty-print a result
      #
      # @param func [String] The name of the function
      # @param orig [String] The original request
      # @param string [String] The processed request
      # @param res [String] The result of the process
      # @return String re-formatted
      def self.pretty(func, orig, string, res)
        orig.gsub!(/[\+\-*\/]/) { |s| " #{s} " }
        string.gsub!(/[\+\-*\/]/) { |s| " #{s} " }
        "#{func.capitalize}: #{orig} (#{string}) ==> #{res}"
      end

      # Roll dice
      #
      # @param string [String] The string representation of the dice roll
      #        example: 2d4+6
      # @return Array of the message and the result
      def self.roll(string)
        results = []
        string.gsub(/\s+/,'').split(',').each do |roll|
          orig = roll
          res = roll.gsub(/[0-9]*d[0-9]*/) do |d|
            num,sides = d.split('d')
            num = num.empty? ? '1' : num
            Array.new(num.to_i.abs) { Random.new.rand(sides.to_i) + 1 }
          end

          results << pretty("Roll", orig, res, solve(res))
        end

        results
      end
    end
  end
end
