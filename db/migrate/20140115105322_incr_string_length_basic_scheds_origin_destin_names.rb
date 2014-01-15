class IncrStringLengthBasicSchedsOriginDestinNames < ActiveRecord::Migration
  def up
	  change_column :basic_schedules, :origin_name, :string, :limit => 50
	  change_column :basic_schedules, :destin_name, :string, :limit => 50
  end

  def down
	  change_column :basic_schedules, :origin_name, :string, :limit => 26
	  change_column :basic_schedules, :destin_name, :string, :limit => 26
  end
end