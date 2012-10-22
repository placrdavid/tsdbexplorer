class StationUpdatesIndexes < ActiveRecord::Migration
   def up
      add_index(:station_updates, :planned_departure_timestamp)
      add_index(:station_updates, :planned_arrival_timestamp)
   end

   def down
      remove_index(:station_updates, :planned_departure_timestamp)
      remove_index(:station_updates, :planned_arrival_timestamp)
   end
end
