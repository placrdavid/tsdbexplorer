class FlattenOrigindeptimeToBasicschedsTable < ActiveRecord::Migration
	def up
		add_column :basic_schedules, :origin_public_departure, :string, :limit => 5 
		
=begin
to update the tables with required values, you can execute the following SQL
      update basic_schedules 
         set origin_public_departure = locations.public_departure
         from locations, tiplocs
         where basic_schedules.uuid like locations.basic_schedule_uuid
         and locations.tiploc_code like tiplocs.tiploc_code
         and locations.location_type = 'LO';
=end 
	end
	
	def down
		remove_column :basic_schedules, :origin_public_departure
	end
end


