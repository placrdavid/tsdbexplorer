class IndexForTimetableLookup < ActiveRecord::Migration
   def change
      add_index(:locations, :next_day_departure) 
      add_index(:locations, :next_day_arrival) 
      #add_index(:locations, :arrival_secs) 
      #add_index(:locations, :departure_secs) 
      add_index(:basic_schedules, :category) 
      add_index(:basic_schedules, :runs_to) 
      add_index(:basic_schedules, :stp_indicator) 
   end
end
