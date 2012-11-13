###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Jul 2012
# A live departures controller
###########################################################

require 'json'

class LiveController < ApplicationController

   # Return all known live updates for a station, in json format
   def stations_updates_json

      # what to order by? planned_departure by default. Must be one planned/predicted_planned_departure/arrival
      order_by = 'planned_departure_timestamp'
      order_options = ['planned_arrival_timestamp', 'predicted_arrival_timestamp', 'planned_departure_timestamp', 'predicted_departure_timestamp']
      unless params[:order_by].nil?
         order_by = params[:order_by] if order_options.include?params[:order_by]
      end

      # Get incoming tiplocs: a comma separated string
      tiplocs_string = params[:tiploc].upcase
      tiplocs_orig_array = tiplocs_string.split(',')
      
      tiplocs_final_array=[]                 

      # for each update, for this station, construct an array of hashes
      tiplocs_orig_array.each do |tiploc|
         # A slection of kludges - this is NOT a longterm solution!! But fixes the CRS <-> tiploc conversion problem in the shortterm
         # the klapham kludge. 
         clapham_tiplocs = [ 'CLPHMJC', 'CLPHMJW', 'CLPHMJM' ]
         tiploc = 'CLPHMJ2' if clapham_tiplocs.include?(tiploc)

         # the wembley kludge
         wembley_tiplocs = [ 'WMBY' ]
         tiploc = 'WMBYDC' if wembley_tiplocs.include?(tiploc)
         tiplocs_final_array.push(tiploc)
      end

       if (order_by == 'planned_arrival_timestamp' or order_by == 'predicted_arrival_timestamp')
         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_arrival)
       else
         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_departure)
       end      

      # Only display passenger schedules in normal mode
       late_range = 2.hour
       @range = Hash.new
       now = DateTime.now
       
      # order by planned_departure       
       @range[:from] = now
       @range[:to] = now + late_range
      @schedule = @schedule.runs_between(@range[:from], @range[:to], false)

      # get the station updates that match this  
      station_updates = StationUpdate.where(:tiploc_code => tiplocs_final_array).includes(:tiploc).includes(:tracked_train).
      order(order_by)

      timetables_array=[] 

      # get timetables
      @schedule.each do |schedule|

         # get the origin / destination
         bs_uuid = schedule[:obj].basic_schedule_uuid
         originloc = Location.where(:basic_schedule_uuid => bs_uuid.to_s).where(:location_type => 'LO')
         destinloc = Location.where(:basic_schedule_uuid => bs_uuid.to_s).where(:location_type => 'LT')

         # TODO could cause problems if now is after midnight
         planned_update_event_day= now
         unless schedule[:obj].public_arrival.nil?
            planned_arrival_hhmm = schedule[:obj].public_arrival
            planned_ds_arrival_day = planned_update_event_day
            planned_ds_arrival_day +=1 if schedule[:obj]['next_day_arrival'] =~ (/(true|t|yes|y|1)$/i)               
            planned_arrival_ts = Time.utc(planned_ds_arrival_day.year,planned_ds_arrival_day.month,planned_ds_arrival_day.day,planned_arrival_hhmm[0,2].to_i,  planned_arrival_hhmm[2,2].to_i)               
         end
         unless schedule[:obj].public_departure.nil?
            planned_departure_hhmm = schedule[:obj].public_departure
            planned_ds_departure_day = planned_update_event_day
            planned_ds_departure_day +=1 if schedule[:obj]['next_day_departure'] =~ (/(true|t|yes|y|1)$/i)               
            planned_departure_ts = Time.utc(planned_ds_departure_day.year,planned_ds_departure_day.month,planned_ds_departure_day.day,planned_departure_hhmm[0,2].to_i,  planned_departure_hhmm[2,2].to_i)               
         end
         matching_station_update = nil
         # get matching updates, based on uuid, and tiploc
         live_movement_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).where( :msg_type => '0003' )

         if live_movement_msgs.size() ==1

            move_msg = JSON.parse(live_movement_msgs[0]['msg_body'])
            event_type = move_msg['event_type']
            variation_status = move_msg['variation_status']
            timetable_variation_mins = move_msg['timetable_variation'].to_i
            unless timetable_variation_mins.nil?
               diff_from_timetable_secs = timetable_variation_mins*60         
               predicted_departure_timestamp = planned_departure_ts+(diff_from_timetable_secs) unless planned_departure_ts.nil?
               predicted_arrival_timestamp = planned_arrival_ts+(diff_from_timetable_secs) unless planned_arrival_ts.nil?
            end
         else
            puts 'catch exceptions where there is no match'
         end         
        timetable_hash = {}
         timetable_hash['tiploc_code'] = schedule[:obj].tiploc_code
         timetable_hash['station_name'] = schedule[:obj].tiploc.tps_description
         timetable_hash['platform'] = schedule[:obj].platform
         timetable_hash['origin_name'] = originloc[0].tiploc.tps_description
         timetable_hash['destination_name'] = destinloc[0].tiploc.tps_description
         timetable_hash['diff_from_timetable_secs'] = 0
         timetable_hash['diff_from_timetable_secs'] = diff_from_timetable_secs unless diff_from_timetable_secs.nil?
         timetable_hash['planned_arrival_timestamp'] = planned_arrival_ts
         timetable_hash['predicted_arrival_timestamp'] = planned_arrival_ts
         timetable_hash['predicted_arrival_timestamp'] = predicted_arrival_timestamp unless predicted_arrival_timestamp.nil?         
         timetable_hash['planned_departure_timestamp'] = planned_departure_ts         
         timetable_hash['predicted_departure_timestamp'] = planned_departure_ts
         timetable_hash['predicted_departure_timestamp'] = predicted_departure_timestamp unless predicted_departure_timestamp.nil?         
         timetable_hash['event_type'] = nil
         timetable_hash['event_type'] =event_type unless event_type.nil?
         timetable_hash['variation_status'] = 'NO REPORT'         
         timetable_hash['variation_status'] = variation_status unless variation_status.nil?
         timetable_hash['operator_ref'] = nil
         timetable_hash['service_name'] = nil
         timetable_hash['service_name'] = schedule[:obj].basic_schedule.service_code unless schedule[:obj].basic_schedule.nil?
         timetable_hash['operator_ref'] = schedule[:obj].basic_schedule.atoc_code unless schedule[:obj].basic_schedule.nil?
         timetables_array << timetable_hash         
      end


      # formulate a hash response
      @response = {}
      @response['tiploc_code'] = tiplocs_final_array
      @response['departures'] = timetables_array

      # transform to json, and respond
      output_json = @response.to_json
      send_data output_json, :type => "text/plain", :disposition => 'inline'
   end
   
   
end
