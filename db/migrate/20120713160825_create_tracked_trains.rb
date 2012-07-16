class CreateTrackedTrains < ActiveRecord::Migration
   def self.up
      create_table :tracked_trains do |t|
         t.string   "msg_type",             :limit => 4
         t.string   "schedule_source",      :limit => 1
         t.string   "train_file_address",   :limit => 4
         t.date     "schedule_end_date"
         t.string   "train_id",             :limit => 10
         t.date     "tp_origin_timestamp"
         t.datetime "creation_timestamp"
         t.string   "tp_origin_stanox",     :limit => 5
         t.datetime "origin_dep_timestamp"
         t.string   "train_service_code",   :limit => 8
         t.string   "toc_id",               :limit => 2
         t.string   "d1266_record_number",  :limit => 5
         t.string   "train_call_type",      :limit => 25
         t.string   "train_uid",            :limit => 6
         t.string   "train_call_mode",      :limit => 25
         t.string   "schedule_type",        :limit => 1
         t.string   "sched_origin_stanox",  :limit => 5
         t.string   "schedule_wtt_id",      :limit => 5
         t.date     "schedule_start_date"
         t.string   "origin_dep_hhmm",      :limit => 5
         t.string   "basic_schedule_uuid",  :limit => 36
         t.string   "origin_name",          :limit => 64
         t.string   "destination_name",     :limit => 64
         t.string   "atoc_code",            :limit => 2
         t.timestamps
      end
      add_index(:tracked_trains, :train_id)
   end

   def self.down
      drop_table :tracked_trains
   end

end
