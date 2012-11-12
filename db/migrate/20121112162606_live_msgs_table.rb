class LiveMsgsTable < ActiveRecord::Migration
 def self.up
      create_table :live_msgs do |t|

         t.string   "msg_type",             :limit => 4
         t.string   "basic_schedule_uuid",  :limit => 36
         t.string   "train_id",             :limit => 10
         t.string   "msg_body",             :limit => 10000
         t.timestamps
      end
      add_index(:live_msgs, :basic_schedule_uuid)
      add_index(:live_msgs, :train_id)
      add_index(:live_msgs, :msg_type)
   end

   def self.down
      drop_table :live_msgs
   end
end
