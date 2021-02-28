# frozen_string_literal: true

require 'active_record'
require 'faraday'
require 'json'
require 'logger'
require 'matrix_sdk'
require 'yaml'

require_relative './matrix'

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

  # Establish configuration for Chronicle
  module Config
    class << self
      # Matrix connection configuration attributes
      attr_accessor :matrix_homeserver, :matrix_access_token

      # Logging configuration attributes
      attr_accessor :log_file, :log_verbose
    end

    # Load a configuration Hash, and store in "module variables"
    #
    # @param config [Hash] a configuration hash
    def self.load_config(config)
      @matrix_homeserver = config["matrix"]["homeserver"]
      @matrix_access_token = config["matrix"]["token"]

      @log_file = config["log"]["file"]
      @log_verbose = config["log"]["debug"]
    end
  end

  def self.start()
    Chronicle::Matrix.start
  end
end
