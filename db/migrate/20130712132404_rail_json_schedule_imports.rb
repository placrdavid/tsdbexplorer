class RailJsonScheduleImports < ActiveRecord::Migration
  def up
      create_table :train_jsonschedule_imports do |t|
         t.timestamp "import_start"
         t.timestamp "import_end"
         t.string "file",  :limit => 500
         t.timestamp "file_lastmod"
         t.string    "full_partial",  :limit => 1
         t.string    "classification",  :limit => 36
         t.timestamp    "source_timestamp"
         t.string    "owner",  :limit => 36
         t.string    "sender_org",  :limit => 36
         t.string    "sender_application",  :limit => 36
         t.string    "sender_component",  :limit => 36
         t.timestamps
      end
   end

  def down
      drop_table :train_jsonschedule_imports
   end
end
