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

class Location < ActiveRecord::Base

  belongs_to :basic_schedule, :primary_key => :uuid, :foreign_key => :basic_schedule_uuid
  has_one :tiploc, :primary_key => :tiploc_code, :foreign_key => :tiploc_code


  # Scopes

#  default_scope :order => 'seq'


=begin  # Join the BasicSchedule model
  scope :join_basic_schedule, lambda {
    joins("JOIN basic_schedules ON locations.basic_schedule_uuid = basic_schedules.uuid").where("basic_schedules.category NOT IN (?) AND basic_schedules.atoc_code NOT IN (?)", $CONFIG['RESTRICTIONS']['category'], $CONFIG['RESTRICTIONS']['toc'])
  }
=end
  scope :join_basic_schedule, lambda {
#    joins("JOIN basic_schedules ON locations.basic_schedule_uuid = basic_schedules.uuid")
    joins("JOIN basic_schedules ON locations.basic_schedule_uuid = basic_schedules.uuid").where("basic_schedules.category NOT IN (?)", $CONFIG['RESTRICTIONS']['category'])
  }


  #TODO origin and destin tiplocs should be arrays
  # Only trains going to a specific origin
#  scope :origin_filter, lambda { |origin| where(' basic_schedules.origin_tiploc = ?', origin) }

  # Only trains going to a specific destination
#  scope :destination_filter, lambda { |destination| where(' basic_schedules.destin_tiploc = ?', destination) }

  # Only trains run by a particular operator
  scope :operator_filter, lambda { |operator_ref| where(' basic_schedules.atoc_code = ?', operator_ref) }

  # Only trains that are part of a particular service
  scope :service_name_filter, lambda { |service_name| where(' basic_schedules.service_code = ?', service_name) }  
  
  scope :schedule_valid_on, lambda { |date|
    where([ 'basic_schedules.runs_su', 'basic_schedules.runs_mo', 'basic_schedules.runs_tu', 'basic_schedules.runs_we', 'basic_schedules.runs_th', 'basic_schedules.runs_fr', 'basic_schedules.runs_sa' ][Date.parse(date).wday] => true ).appropriate_stp_indicator(date)
  }
  

  # Only trains which run on a specific date

  scope :runs_on, lambda { |date| join_basic_schedule.where('? BETWEEN basic_schedules.runs_from AND basic_schedules.runs_to', date).schedule_valid_on(date) }


  # Limit the search to passenger categories

  scope :only_passenger, lambda { join_basic_schedule.where("category IN ('OL', 'OU', 'OO', 'OW', 'XC', 'XD', 'XI', 'XR', 'XU', 'XX', 'XD', 'XZ', 'BR', 'BS')") }
  # TODO: Create an :only_freight scope


  # Limits search to schedules valid for a particular day of the week

  scope :schedule_valid_on, lambda { |date|
    where([ 'basic_schedules.runs_su', 'basic_schedules.runs_mo', 'basic_schedules.runs_tu', 'basic_schedules.runs_we', 'basic_schedules.runs_th', 'basic_schedules.runs_fr', 'basic_schedules.runs_sa' ][Date.parse(date).wday] => true ).appropriate_stp_indicator(date)
  }


  # Pick the most appropriate schedule - Permanent, Overlay, STP, Cancellation
  scope :appropriate_stp_indicator, lambda { |date|
    where('stp_indicator IN (SELECT MIN(stp_indicator) FROM basic_schedules AS bs2 WHERE train_uid = basic_schedules.train_uid AND ? BETWEEN runs_from AND runs_to)', date)
  }


  # Return trains arriving or departing between the specified times

  scope :calls_between, lambda { |from_time,to_time|
    where('(locations.arrival_secs BETWEEN ? AND ?) OR (locations.departure_secs BETWEEN ? AND ?)', TSDBExplorer::time_to_seconds(from_time), TSDBExplorer::time_to_seconds(to_time), TSDBExplorer::time_to_seconds(from_time), TSDBExplorer::time_to_seconds(to_time))
  }


  # Return trains arriving, departing or passing between the specified times

  scope :passes_between, lambda { |from_time,to_time|
    where('(locations.arrival_secs BETWEEN ? AND ?) OR (locations.pass_secs BETWEEN ? AND ?) OR (locations.departure_secs BETWEEN ? AND ?)', TSDBExplorer::time_to_seconds(from_time), TSDBExplorer::time_to_seconds(to_time), TSDBExplorer::time_to_seconds(from_time), TSDBExplorer::time_to_seconds(to_time), TSDBExplorer::time_to_seconds(from_time), TSDBExplorer::time_to_seconds(to_time))
  }


  # Limits search to trains travelling to or from a particular location

  scope :runs_to, lambda { |loc|
    joins('LEFT JOIN locations loc_to ON locations.basic_schedule_uuid = loc_to.basic_schedule_uuid').where('loc_to.tiploc_code IN (?) AND locations.seq < loc_to.seq', loc)
  }

  scope :runs_from, lambda { |loc|
    joins('LEFT JOIN locations loc_from ON locations.basic_schedule_uuid = loc_from.basic_schedule_uuid').where('loc_from.tiploc_code IN (?) AND locations.seq > loc_from.seq', loc)
  }


  # Return an ActiveRecord::Relation object containing all the schedules which arrive, pass or depart a location within a specific time window
# TODO origin and destin tiplocs should be arrays!
  def self.runs_between(from, to, show_passing, 
	  #origin_tiploc,
	  #destination_tiploc,
	  operator_ref,
	  service_name 
	  )

    queries = Hash.new

    trains = Array.new

    # We're going to be forming a Location query
    schedule_base = Location
	 
	 # add the origin filter, if not nil
	 #schedule_base = schedule_base.origin_filter(origin_tiploc) unless origin_tiploc.nil?
	 # add the destination filter, if not nil
	 #schedule_base = schedule_base.destination_filter(destination_tiploc) unless destination_tiploc.nil?
	 # add the ? filter, if not nil
	 schedule_base = schedule_base.operator_filter(operator_ref) unless operator_ref.nil?
	 # add the service_name filter, if not nil
	 schedule_base = schedule_base.service_name_filter(service_name) unless service_name.nil?
	 
	     
    if from.midnight == to.midnight
      # The time window doesn't span midnight, so retrieve the following schedules:
      #
      #   - Runs today and calls within the time window
      #   - Ran yesterday and calls within the time window with the next-day flag set

      run_date = from.midnight

      # Return all schedules which run today and call on this day within the window

      q1 = schedule_base.runs_on(from.to_s(:yyyymmdd)).where('locations.next_day_departure = false OR locations.next_day_arrival = false').includes(:basic_schedule)
      #q1.destination_filter(destination_tiploc) unless destination_tiploc.nil?
		
#      q1 =				schedule_base.runs_on(from.to_s(:yyyymmdd)).destination_tiploc(destination_tiploc).where('locations.next_day_departure = false OR locations.next_day_arrival = false').includes(:basic_schedule)

#

      if show_passing == true
        q1 = q1.passes_between(from.to_s(:hhmm), to.to_s(:hhmm))
      else
        q1 = q1.calls_between(from.to_s(:hhmm), to.to_s(:hhmm))
      end

      q1.each do |s|
        trains.push({ :a => s.arrival_secs.nil? ? nil : run_date + s.arrival_secs, :p => s.pass_secs.nil? ? nil : run_date + s.pass_secs, :d => s.departure_secs.nil? ? nil : run_date + s.departure_secs, :runs_on => run_date, :obj => s })
      end


      # Return all schedules which ran yesterday and call on the next day within the window (i.e. over midnight)



#      q2 = schedule_base.runs_on((from - 1.day).to_s(:yyyymmdd)).destination_filter(destination_tiploc).where('locations.next_day_departure = true OR locations.next_day_arrival = true').includes(:basic_schedule)

      q2 = schedule_base.runs_on((from - 1.day).to_s(:yyyymmdd)).where('locations.next_day_departure = true OR locations.next_day_arrival = true').includes(:basic_schedule)
      #q2.destination_filter(destination_tiploc) unless destination_tiploc.nil?

      if show_passing == true
        q2 = q2.passes_between(from.to_s(:hhmm), to.to_s(:hhmm))
      else
        q2 = q2.calls_between(from.to_s(:hhmm), to.to_s(:hhmm))
      end

      q2.each do |s|
        trains.push({ :a => s.arrival_secs.nil? ? nil : run_date + s.arrival_secs, :p => s.pass_secs.nil? ? nil : run_date + s.pass_secs, :d => s.departure_secs.nil? ? nil : run_date + s.departure_secs, :runs_on => run_date - 1.day, :obj => s })
      end

    else
      puts 'from.midnight != to.midnight'
      # The time window spans midnight, so retrieve the following schedules:
      #
      #  - Runs on the day before midnight and calls up until midnight
      #  - Runs on the day before midnight and calls after midnight
      #  - Runs on the day after midnight and calls between midnight and the end of the time window

      day_before_midnight = from.midnight
      day_after_midnight = to.midnight
      puts 'day_before_midnight '+day_before_midnight.to_s
      puts 'day_after_midnight '+day_after_midnight.to_s
      # Return all schedules which run on the day before midnight and call up until midnight



#      q1 = schedule_base.runs_on(day_before_midnight.to_s(:yyyymmdd)).destination_tiploc(destination_tiploc).where('locations.next_day_departure = false OR locations.next_day_arrival = false').includes(:basic_schedule)
      q1 = schedule_base.runs_on(day_before_midnight.to_s(:yyyymmdd)).where('locations.next_day_departure = false OR locations.next_day_arrival = false').includes(:basic_schedule)
      #q1.destination_filter(destination_tiploc) unless destination_tiploc.nil?


      if show_passing == true
        q1 = q1.passes_between(from.to_s(:hhmm), "2359H")
      else
        q1 = q1.calls_between(from.to_s(:hhmm), "2359H")
      end

      q1.each do |s|
        trains.push({ :a => s.arrival_secs.nil? ? nil : day_before_midnight + s.arrival_secs, :p => s.pass_secs.nil? ? nil : day_before_midnight + s.pass_secs, :d => s.departure_secs.nil? ? nil : day_before_midnight + s.departure_secs, :runs_on => day_before_midnight, :obj => s })
      end


      # Return all schedules which run on the day before midnight and call after midnight

#      q2 = schedule_base.runs_on(day_before_midnight.to_s(:yyyymmdd)).destination_tiploc(destination_tiploc).where('locations.next_day_departure = true OR locations.next_day_arrival = true').includes(:basic_schedule)
      q2 = schedule_base.runs_on(day_before_midnight.to_s(:yyyymmdd)).where('locations.next_day_departure = true OR locations.next_day_arrival = true').includes(:basic_schedule)
      #q2.destination_filter(destination_tiploc) unless destination_tiploc.nil?

      if show_passing == true
        q2 = q2.passes_between('0000', to.to_s(:hhmm))
      else
        q2 = q2.calls_between('0000', to.to_s(:hhmm))
      end

      q2.each do |s|
        trains.push({ :a => s.arrival_secs.nil? ? nil : day_after_midnight + s.arrival_secs, :p => s.pass_secs.nil? ? nil : day_after_midnight + s.pass_secs, :d => s.departure_secs.nil? ? nil : day_after_midnight + s.departure_secs, :runs_on => day_before_midnight, :obj => s })
      end


      # Return all schedules which run on the day after midnight and call between midnight and the end of the time window

#      q3 = schedule_base.runs_on(to.to_s(:yyyymmdd)).destination_tiploc(destination_tiploc).where('locations.next_day_departure = false AND locations.next_day_arrival = false').includes(:basic_schedule)
      q3 = schedule_base.runs_on(to.to_s(:yyyymmdd)).where('locations.next_day_departure = false AND locations.next_day_arrival = false').includes(:basic_schedule)
		#q3.destination_filter(destination_tiploc) unless destination_tiploc.nil?

      if show_passing == true
        q3 = q3.passes_between('0000', to.to_s(:hhmm))
      else
        q3 = q3.calls_between('0000', to.to_s(:hhmm))
      end

      q3.each do |s|
        trains.push({ :a => s.arrival_secs.nil? ? nil : day_after_midnight + s.arrival_secs, :p => s.pass_secs.nil? ? nil : day_after_midnight + s.pass_secs, :d => s.departure_secs.nil? ? nil : day_after_midnight + s.departure_secs, :runs_on => day_after_midnight, :obj => s })
      end


    end

    return trains

  end


  # Get the n departures for this station, at the specified time / date
   def Location.get_departures(tiploc_code_array, starttime, endtime, n)

      start_hhmm = Location.date_to_hhmm(starttime)
      end_hhmm = Location.date_to_hhmm(endtime)


      deps = Location.runs_on(starttime.to_s).where(:tiploc_code => tiploc_code_array).
            where('public_departure >= ?', start_hhmm).
            where('public_departure <= ?', end_hhmm).
            order(:public_departure).limit(n)            
      return deps
   end
   
   

  # Returns true if this location is a publically advertised location, for
  # example, the origin or destination, calling points and pick-up or
  # set-down points

  def is_public?
    [:activity_tb, :activity_tf, :activity_t, :activity_d, :activity_u, :activity_r].each do |a|
      return true if self.send(a) == true
    end
    return false
  end


  # Returns true if this location is to pick up passengers only

  def pickup_only?
    self.activity_u == true
  end


  # Returns true if this location is to set down passengers only

  def setdown_only?
    self.activity_d == true
  end


  # Returns true if the schedule starts at this location

  def is_origin?
    self.activity_tb == true
  end


  # Returns true if the schedule finishes at this location

  def is_destination?
    self.activity_tf == true
  end

   # extracts a hhmm string from a ruby timestamp
   def Location.date_to_hhmm(datetimestamp)
      hh = datetimestamp.hour.to_s
      hh = '0'+hh if datetimestamp.hour < 10
      mm = datetimestamp.min.to_s
      mm = '0'+mm if datetimestamp.min < 10
      return hh + mm
   end
   
end
