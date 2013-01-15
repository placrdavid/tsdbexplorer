class DropStationUpdatesTable < ActiveRecord::Migration
  def up
    drop_table :station_updates
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
