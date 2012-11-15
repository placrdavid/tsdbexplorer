class FlattenOriginDestinationToBasicschedsTable < ActiveRecord::Migration
   def up

      add_column :basic_schedules, :origin_tiploc, :string, :limit => 7 
      add_column :basic_schedules, :origin_name, :string, :limit => 26 
      add_column :basic_schedules, :destin_tiploc, :string, :limit => 7 
      add_column :basic_schedules, :destin_name, :string, :limit => 26

=begin
to update the tables with required values, you can execute the following SQL
      update basic_schedules 
         set origin_tiploc = locations.tiploc_code, origin_name = tiplocs.tps_description
         from locations, tiplocs
         where basic_schedules.uuid like locations.basic_schedule_uuid
         and locations.tiploc_code like tiplocs.tiploc_code
         and locations.location_type = 'LO';
      update basic_schedules 
         set destin_tiploc = locations.tiploc_code, destin_name = tiplocs.tps_description
         from locations, tiplocs
         where basic_schedules.uuid like locations.basic_schedule_uuid
         and locations.tiploc_code like tiplocs.tiploc_code
         and locations.location_type = 'LT';
=end      
   end

   def down
      remove_column :basic_schedules, :origin_tiploc
      remove_column :basic_schedules, :origin_name
      remove_column :basic_schedules, :destin_tiploc
      remove_column :basic_schedules, :destin_name
   end
end
