class CreateStationUpdates < ActiveRecord::Migration

   def self.up
      create_table :station_updates do |t|
         t.string   "tiploc_code",              :limit => 7
         t.string   "location_type",            :limit => 2
         t.string   "platform",                 :limit => 64
         t.string   "train_id",                 :limit => 10
         t.integer  "diff_from_timetable_secs"
         t.string   "planned_arrival",          :limit => 4
         t.string   "predicted_arrival",        :limit => 4
         t.string   "planned_departure",        :limit => 4
         t.string   "predicted_departure",      :limit => 4
         t.string   "event_type",               :limit => 32
         t.string   "planned_event_type",       :limit => 32
         t.string   "variation_status",         :limit => 32
         t.timestamps
      end
      add_index(:station_updates, :train_id)
      add_index(:station_updates, :platform)
      add_index(:station_updates, :tiploc_code)
   end

   def self.down
      drop_table :station_updates
   end
end
