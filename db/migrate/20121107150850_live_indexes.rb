class LiveIndexes < ActiveRecord::Migration
   def change
      add_index(:tracked_trains, :basic_schedule_uuid) 
   end
end
