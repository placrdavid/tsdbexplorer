class IndexesForLiveUpdates < ActiveRecord::Migration
   def change
      add_index(:basic_schedules, :runs_from)
      add_index(:basic_schedules, :service_code)
      add_index(:locations, :seq)
      add_index(:locations, :public_arrival)
      add_index(:locations, :public_departure)
   end
end
