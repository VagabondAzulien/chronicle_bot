namespace :chronicle do
  desc 'Start the bot'
  task :start do
    require 'active_record'
    require_relative 'lib/chronicle'

    db_config = YAML::load(File.open('config/database.yml'))
    ActiveRecord::Base.establish_connection(db_config)

    bot_config = YAML::load(File.open('config/bot.yml'))
    Chronicle::Config.load_config(bot_config)

    Chronicle.start
  end
end

namespace :db do
  require 'active_record'
  require 'yaml'

  Dir[File.join(__dir__, 'db', 'migrate', '*.rb')].each do |file|
    require file
  end

  task :connect do
    connection_details = YAML::load(File.open('config/database.yml'))
    ActiveRecord::Base.establish_connection(connection_details)
  end

  desc "Create a new database"
  task :create do
    connection_details = YAML::load(File.open('config/database.yml'))

    if connection_details["adapter"] == 'sqlite3'
      if File.exists?(connection_details["database"])
        puts 'DB already exists' 
      else
        File.open(connection_details["database"], 'w+') {}
      end
    else
      ActiveRecord::Base.establish_connection(connection_details)
      ActiveRecord::Base.connection.create_database(
        connection_details["database"]
      )
    end
  end

  desc "Run the migrations"
  task :migrate => 'db:connect' do
    # ActiveRecord::MigrationContext.new('db/migrate/').migrate()
    CreateCustomCommands.migrate(:up)
  end

  desc "Clear the database"
  task :drop => 'db:connect' do
    # ActiveRecord::Migration.migrate(:down)
    CreateCustomCommands.migrate(:down)
  end
end
