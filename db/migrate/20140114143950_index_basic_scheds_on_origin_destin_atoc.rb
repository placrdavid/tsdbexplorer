class IndexBasicSchedsOnOriginDestinAtoc < ActiveRecord::Migration
  def change
     add_index(:basic_schedules, :destin_tiploc) 
     add_index(:basic_schedules, :origin_tiploc) 
     add_index(:basic_schedules, :atoc_code) 
  end

end
