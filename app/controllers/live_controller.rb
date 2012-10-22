###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Jul 2012
# A live departures controller
###########################################################

class LiveController < ApplicationController


   # Return all known live updates for a station, in json format
   def stations_updates_json_old

=begin old way
      # what to order by? planned_departure by default. Must be one planned/predicted_planned_departure/arrival
      order_by = 'planned_departure_timestamp'
      order_options = ['planned_arrival_timestamp', 'predicted_arrival_timestamp', 'planned_departure_timestamp', 'predicted_departure_timestamp']
      unless params[:order_by].nil?
         order_by = params[:order_by] if order_options.include?params[:order_by]
      end

      tiploc =  params[:tiploc]

      # Get matching station_updates
      # A slection of kludges - this is NOT a longterm solution!! But fixes the CRS <-> tiploc conversion problem in the shortterm
      # the klapham kludge. 
      clapham_tiplocs = [ 'CLPHMJC', 'CLPHMJW', 'CLPHMJM' ]
      tiploc = 'CLPHMJ2' if clapham_tiplocs.include?(tiploc)

      # the wembley kludge
      wembley_tiplocs = [ 'WMBY' ]
      tiploc = 'WMBYDC' if wembley_tiplocs.include?(tiploc)

      station_updates = StationUpdate.where(:tiploc_code => tiploc).includes(:tiploc).includes(:tracked_train).
      #station_updates = StationUpdate.where(:tiploc_code => tiplocs_final_array).includes(:tiploc).includes(:tracked_train).
      order(order_by)
      updates_array=[]                 

      # for each update, for this station, construct an array of hashes
      station_updates.each do |station_update|

         update_hash = {}
         update_hash['tiploc_code'] = station_update.tiploc_code
         update_hash['station_name'] = station_update.tiploc.tps_description
         update_hash['platform'] = station_update.platform
         update_hash['origin_name'] = station_update.tracked_train.origin_name
         update_hash['destination_name'] = station_update.tracked_train.destination_name
         update_hash['diff_from_timetable_secs'] = station_update.diff_from_timetable_secs
         update_hash['planned_arrival_timestamp'] = station_update.planned_arrival_timestamp
         update_hash['predicted_arrival_timestamp'] = station_update.predicted_arrival_timestamp
         update_hash['planned_departure_timestamp'] = station_update.planned_departure_timestamp
         update_hash['predicted_departure_timestamp'] = station_update.predicted_departure_timestamp
         update_hash['event_type'] = station_update.event_type
         update_hash['variation_status'] = station_update.variation_status         
         update_hash['service_name'] = station_update.tracked_train.train_service_code
         update_hash['operator_ref'] = station_update.tracked_train.atoc_code
         updates_array << update_hash

      end

      # formulate a hash response
      @response = {}
      @response['tiploc_code'] = tiploc
      @response['departures'] = updates_array

      # transform to json, and respond
      output_json = @response.to_json
      send_data output_json, :type => "text/plain", :disposition => 'inline'
   end
=end

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

      station_updates = StationUpdate.where(:tiploc_code => tiplocs_final_array).includes(:tiploc).includes(:tracked_train).
      order(order_by)
      updates_array=[]                 

      # for each update, for this station, construct an array of hashes
      station_updates.each do |station_update|
   
         update_hash = {}
         update_hash['tiploc_code'] = station_update.tiploc_code
         update_hash['station_name'] = station_update.tiploc.tps_description
         update_hash['platform'] = station_update.platform
         update_hash['origin_name'] = station_update.tracked_train.origin_name
         update_hash['destination_name'] = station_update.tracked_train.destination_name
         update_hash['diff_from_timetable_secs'] = station_update.diff_from_timetable_secs
         update_hash['planned_arrival_timestamp'] = station_update.planned_arrival_timestamp
         update_hash['predicted_arrival_timestamp'] = station_update.predicted_arrival_timestamp
         update_hash['planned_departure_timestamp'] = station_update.planned_departure_timestamp
         update_hash['predicted_departure_timestamp'] = station_update.predicted_departure_timestamp
         update_hash['event_type'] = station_update.event_type
         update_hash['variation_status'] = station_update.variation_status         
         update_hash['service_name'] = station_update.tracked_train.train_service_code
         update_hash['operator_ref'] = station_update.tracked_train.atoc_code
         updates_array << update_hash
      end

      # formulate a hash response
      @response = {}
      @response['tiploc_code'] = tiplocs_final_array
      @response['departures'] = updates_array

      # transform to json, and respond
      output_json = @response.to_json
      send_data output_json, :type => "text/plain", :disposition => 'inline'
   end


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

      # search for a matching update on departure/arrival time
      if planned_departure_ts !=nil
         station_updates_matches = station_updates.where(:planned_departure_timestamp => planned_departure_ts)
      elsif  planned_arrival_ts !=nil 
         station_updates_matches = station_updates.where(:planned_arrival_timestamp => planned_arrival_ts)
      end
       
      matching_station_update = nil
      # now find matches on origin
      station_updates_matches.each do |station_updates_match|
         if station_updates_match.tracked_train.origin_name == originloc[0].tiploc.tps_description
            matching_station_update = station_updates_match
         end
      end
      
      

        timetable_hash = {}
         timetable_hash['tiploc_code'] = schedule[:obj].tiploc_code
         timetable_hash['station_name'] = schedule[:obj].tiploc.tps_description
         timetable_hash['platform'] = schedule[:obj].platform
         timetable_hash['origin_name'] = originloc[0].tiploc.tps_description
         timetable_hash['destination_name'] = destinloc[0].tiploc.tps_description
         timetable_hash['diff_from_timetable_secs'] = 0
         timetable_hash['diff_from_timetable_secs'] = matching_station_update.diff_from_timetable_secs unless matching_station_update.nil?
         timetable_hash['planned_arrival_timestamp'] = planned_arrival_ts
         timetable_hash['predicted_arrival_timestamp'] = planned_arrival_ts
         timetable_hash['predicted_arrival_timestamp'] = matching_station_update.predicted_arrival_timestamp unless matching_station_update.nil?         
         timetable_hash['planned_departure_timestamp'] = planned_departure_ts         
         timetable_hash['predicted_departure_timestamp'] = planned_departure_ts
         timetable_hash['predicted_departure_timestamp'] = matching_station_update.predicted_departure_timestamp unless matching_station_update.nil?         
         timetable_hash['event_type'] = 'ACTIVATION'
         timetable_hash['event_type'] = matching_station_update.event_type unless matching_station_update.nil?         
         timetable_hash['variation_status'] = 'NO REPORT'         
         timetable_hash['variation_status'] = matching_station_update.variation_status       unless matching_station_update.nil?            
         timetable_hash['operator_ref'] = nil
         timetable_hash['service_name'] = nil
         timetable_hash['service_name'] = schedule[:obj].basic_schedule.service_code unless schedule[:obj].basic_schedule.nil?
         timetable_hash['operator_ref'] = schedule[:obj].basic_schedule.atoc_code unless schedule[:obj].basic_schedule.nil?
         timetables_array << timetable_hash         
      end


      # formulate a hash response
      @response = {}
      @response['tiploc_code'] = tiplocs_final_array
      #@response['departures'] = updates_array
      @response['departures'] = timetables_array

      # transform to json, and respond
      output_json = @response.to_json
      send_data output_json, :type => "text/plain", :disposition => 'inline'
   end
   
end

