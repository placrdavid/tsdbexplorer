class StationUpdatesHhmmAsTimestamps < ActiveRecord::Migration
  def up
     # create new cols for planned / predicted arrs / deps as UTC timestamps
     add_column :station_updates, :planned_arrival_timestamp, :timestamp
     add_column :station_updates, :planned_departure_timestamp, :timestamp
     add_column :station_updates, :predicted_arrival_timestamp, :timestamp
     add_column :station_updates, :predicted_departure_timestamp, :timestamp

     # populate new cols (we assume todays date, so better to run this early in day)
      execute <<-SQL
         update station_updates set planned_arrival_timestamp = 
         cast(cast(CURRENT_DATE||' '||substring(planned_arrival from 1 for 2)||':'||substring(planned_arrival from 3 for 2)||'' as text) as timestamp)
         where planned_arrival is not null;
      SQL
      execute <<-SQL
         update station_updates set predicted_arrival_timestamp = 
         cast(cast(CURRENT_DATE||' '||substring(predicted_arrival from 1 for 2)||':'||substring(predicted_arrival from 3 for 2)||'' as text) as timestamp)
         where predicted_arrival is not null;
      SQL

      execute <<-SQL
         update station_updates set planned_departure_timestamp = 
         cast(cast(CURRENT_DATE||' '||substring(planned_departure from 1 for 2)||':'||substring(planned_departure from 3 for 2)||'' as text) as timestamp)
         where planned_departure is not null;
      SQL

      execute <<-SQL
         update station_updates set predicted_departure_timestamp = 
         cast(cast(CURRENT_DATE||' '||substring(predicted_departure from 1 for 2)||':'||substring(predicted_departure from 3 for 2)||'' as text) as timestamp)
         where predicted_departure is not null;
      SQL

     # drop old hhmm format columns
     remove_column :station_updates, :planned_arrival
     remove_column :station_updates, :planned_departure
     remove_column :station_updates, :predicted_arrival
     remove_column :station_updates, :predicted_departure

  end

  def down
     # create cols for planned / predicted arrs / deps as hhmm
     
     add_column :station_updates, :planned_arrival,      :string,    :limit => 4
     add_column :station_updates, :predicted_arrival,    :string,    :limit => 4
     add_column :station_updates, :planned_departure,    :string,    :limit => 4
     add_column :station_updates, :predicted_departure,  :string,    :limit => 4

     # populate hhmm cols
      execute <<-SQL
         update station_updates set planned_arrival =
         substring(cast(planned_arrival_timestamp as text) from 12 for 2)|| substring(cast(planned_arrival_timestamp as text) from 15 for 2)
         where planned_arrival_timestamp is not null;
      SQL

      execute <<-SQL
         update station_updates set predicted_arrival =
         substring(cast(predicted_arrival_timestamp as text) from 12 for 2)|| substring(cast(predicted_arrival_timestamp as text) from 15 for 2)
         where predicted_arrival_timestamp is not null;
      SQL

      execute <<-SQL
         update station_updates set planned_departure =
         substring(cast(planned_departure_timestamp as text) from 12 for 2)|| substring(cast(planned_departure_timestamp as text) from 15 for 2)
         where planned_departure_timestamp is not null;
      SQL

      execute <<-SQL
         update station_updates set predicted_departure =
         substring(cast(predicted_departure_timestamp as text) from 12 for 2)|| substring(cast(predicted_departure_timestamp as text) from 15 for 2)
         where predicted_departure_timestamp is not null;
      SQL

     # drop utc format columns
     remove_column :station_updates, :planned_arrival_timestamp
     remove_column :station_updates, :planned_departure_timestamp
     remove_column :station_updates, :predicted_arrival_timestamp
     remove_column :station_updates, :predicted_departure_timestamp
  end
end
