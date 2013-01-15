class TrainMovementsTableTimestampsAsLong < ActiveRecord::Migration
  def up
#   change_column :train_movements, :planned_timestamp, :integer, :limit => 8
#   change_column :train_movements, :actual_timestamp, :integer, :limit => 8
   remove_column :train_movements, :planned_timestamp
   add_column :train_movements, :planned_timestamp, :integer, :limit => 8
   remove_column :train_movements, :actual_timestamp
   add_column :train_movements, :actual_timestamp, :integer, :limit => 8    
  end

  def down
#   change_column :train_movements, :planned_timestamp, :timestamp
#   change_column :train_movements, :actual_timestamp, :timestamp
   remove_column :train_movements, :planned_timestamp
   add_column :train_movements, :planned_timestamp, :timestamp
   remove_column :train_movements, :actual_timestamp
   add_column :train_movements, :actual_timestamp, :timestamp   

  end
end
