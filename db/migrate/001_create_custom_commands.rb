class CreateCustomCommands < ActiveRecord::Migration[5.2]
  def up
    create_table :custom_commands do |table|
      table.string :roomid
      table.string :command
      table.string :response
      table.timestamps
    end
  end

  def down
    drop_table :custom_commands
  end
end
