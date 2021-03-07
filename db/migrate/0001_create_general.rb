class CreateGeneral < ActiveRecord::Migration[6.1]
  def up
    create_table :general do |table|
      table.string :roomid
      table.string :protocol
      table.string :prefix_char
      table.integer :permission_level
      table.timestamps
    end
  end

  def down
    drop_table :general
  end
end
