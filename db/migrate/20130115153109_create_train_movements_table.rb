class CreateTrainMovementsTable < ActiveRecord::Migration
  def up
      create_table :train_movements do |t|
         t.string    "basic_schedule_uuid",  :limit => 36
         t.string    "train_id",             :limit => 10
         t.string    "event_type",           :limit => 32
         t.timestamp "planned_timestamp"
         t.timestamp "actual_timestamp"
         t.integer	 "timetable_variation"
         t.integer	 "secs_late"
         t.string    "loc_stanox",           :limit => 5
         t.string    "platform",             :limit => 64
         t.boolean   "train_terminated"
         t.string    "train_id",             :limit => 10
         t.string    "variation_status",     :limit => 32
         t.string    "train_service_code",   :limit => 8
         t.string    "toc_id",               :limit => 2
         t.timestamps
      end
      add_index(:train_movements, :basic_schedule_uuid)
      add_index(:train_movements, :loc_stanox)
   end

  def down
      drop_table :train_movements
   end
end

