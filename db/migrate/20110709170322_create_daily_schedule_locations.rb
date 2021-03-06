#
#  This file is part of TSDBExplorer.
#
#  TSDBExplorer is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
#
#  TSDBExplorer is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
#  Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with TSDBExplorer.  If not, see <http://www.gnu.org/licenses/>.
#
#  $Id$
#

class CreateDailyScheduleLocations < ActiveRecord::Migration

  def self.up

    create_table :daily_schedule_locations do |t|
      t.string     :daily_schedule_uuid, :limit => 36
      t.string     :location_type, :limit => 2
      t.string     :tiploc_code, :limit => 7
      t.integer    :tiploc_instance
      t.boolean    :cancelled
      t.datetime   :cancellation_timestamp
      t.string     :cancellation_reason, :limit => 2
      t.datetime   :arrival
      t.datetime   :expected_arrival
      t.datetime   :actual_arrival
      t.datetime   :public_arrival
      t.datetime   :expected_pass
      t.datetime   :pass
      t.datetime   :actual_pass
      t.datetime   :expected_departure
      t.datetime   :departure
      t.datetime   :actual_departure
      t.datetime   :public_departure
      t.string     :platform, :limit => 3
      t.string     :actual_platform, :limit => 3
      t.string     :line, :limit => 3
      t.string     :actual_line, :limit => 3
      t.string     :path, :limit => 3
      t.string     :actual_path, :limit => 3
      t.integer    :engineering_allowance
      t.integer    :pathing_allowance
      t.integer    :performance_allowance
      t.string     :activity, :limit => 12
      t.timestamps
    end

    add_index(:daily_schedule_locations, :daily_schedule_uuid)
    add_index(:daily_schedule_locations, :arrival)
    add_index(:daily_schedule_locations, :pass)
    add_index(:daily_schedule_locations, :departure)

  end

  def self.down
    drop_table :daily_schedule_locations
  end

end
