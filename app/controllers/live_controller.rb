###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Jul 2012
# A live departures controller
###########################################################

require 'json'

class LiveController < ApplicationController

   
=begin   
   # Return all known live updates for a station, in json format
   def stations_updates_json


startt = Time.now
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
=begin
       if (order_by == 'planned_arrival_timestamp' or order_by == 'predicted_arrival_timestamp')
         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_arrival)
       else
         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_departure)
       end      

      # Only display passenger schedules in normal mode
       before_range = 1.hour
       after_range = 2.hour
       @range = Hash.new
       now = DateTime.now
       
      # order by planned_departure       
       @range[:from] = now -before_range
       @range[:to] = now + after_range
      @schedule = @schedule.runs_between(@range[:from], @range[:to], false)
 =end


      # Only display passenger schedules in normal mode
       before_range = 1.hour
       after_range = 2.hour
       @range = Hash.new
       now = DateTime.now
       @range[:from] = now -before_range
       @range[:to] = now + after_range

=begin
      @schedule = Location.where(:tiploc_code => tiplocs_final_array).runs_between(@range[:from], @range[:to], false)
      # order by planned_departure       
      #@schedule = @schedule.runs_between(@range[:from], @range[:to], false)
      puts 'n scheduled stops = '+@schedule.size.to_s
      @schedule.each do |schedule|
         puts 'we got a scheduled stop'
      end
 =end
#=begin
      @scheduled_stops = Location.get_departures(tiplocs_final_array, @range[:from], @range[:to], 100)
      puts 'n scheduled stops = '+@scheduled_stops.size.to_s
      @scheduled_stops.each do |scheduled_stop|
         puts 'we got a scheduled stop'
      end
#=end
=begin
      # incoming time/date/crscode/limit
#      datestr = params[:date]
#      timestr =params[:time]
#      date_time = DateTimeFormatting.yyyyhmmhdd_hhcmm_string_to_timestamp(datestr, timestr)
#      crscode = params[:stationcode]

      # get the a single CRS record associated with this code
      crs_record = Train_Crs.find_by_crs(crscode)
      if crs_record.nil?
         msg = "no stations match the CRS code "+crscode
         render_short_msg(ERROR_KEY_NAME, msg, @format)
         return 
      end
      # there may be multiple tiploc codes - returned as an array
      tiploc_codes_array = crs_record.tiplocs_as_array()            
      # get the single station name, for this CRS
      station_name = crs_record.get_description()
      
 =begin
      called_at_crsrecord = Train_Crs.find_by_crs(params[:called_at]) 
      called_at_tiploc_csv_singlequoted = called_at_crsrecord.tiplocs_as_csvstring_with_singlequotes() unless called_at_crsrecord.nil?
      calling_at_crsrecord = Train_Crs.find_by_crs(params[:calling_at]) 
      calling_at_tiploc_csv_singlequoted = calling_at_crsrecord.tiplocs_as_csvstring_with_singlequotes() unless calling_at_crsrecord.nil?
      origin_crsrecord = Train_Crs.find_by_crs(params[:origin]) 
      origin_tiploc_csv_singlequoted = origin_crsrecord.tiplocs_as_csvstring_with_singlequotes() unless origin_crsrecord.nil?
      destination_crsrecord = Train_Crs.find_by_crs(params[:destination])  
      destination_tiploc_csv_singlequoted = destination_crsrecord.tiplocs_as_csvstring_with_singlequotes() unless destination_crsrecord.nil?
 =end

      # get matching departures, up to limit
      #limit = departures_limit(params[:limit].to_i)            
      locs = TrainScheduledStop.get_departures(tiploc_codes_array, date_time, limit, 
      origin_tiploc_csv_singlequoted, destination_tiploc_csv_singlequoted, called_at_tiploc_csv_singlequoted, 
      calling_at_tiploc_csv_singlequoted)
 =end


=begin      timetables_array=[] 

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
 =end
=begin
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
 =end      

=begin
diff_from_timetable_secs = nil
predicted_arrival_timestamp = nil
predicted_departure_timestamp = nil
event_type = nil
variation_status = nil
         
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

 =end
      # formulate a hash response
      @response = {}
      @response['tiploc_code'] = tiplocs_final_array
      @response['departures'] = {}

      # transform to json, and respond
      output_json = @response.to_json
      
checkt = Time.now
elapsed = checkt - startt
puts 'time to run entire query = '+elapsed.to_s

      send_data output_json, :type => "text/plain", :disposition => 'inline'
   end
=end   

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

      timetables_array=[] 

      # get timetables
      @schedule.each do |schedule|

         # get the origin / destination - speed this up

#
         bs_uuid = schedule[:obj].basic_schedule_uuid
=begin
#         originloc = Location.where(:basic_schedule_uuid => bs_uuid.to_s).where(:location_type => 'LO')
#         destinloc = Location.where(:basic_schedule_uuid => bs_uuid.to_s).where(:location_type => 'LT')
         originloc = schedule[:obj].basic_schedule.origin
         destinloc = schedule[:obj].basic_schedule.terminate
         origin_name = originloc.tiploc.tps_description
         destin_name = destinloc.tiploc.tps_description
         #timetable_hash['destination_name'] = destinloc[0].tiploc.tps_description
#         puts 'get origin...'
#puts 'standalone query = '+originloc[0].tiploc.tps_description
#puts 'integrated query = '+originloca.tiploc.tps_description
#         puts 'get destination...'
#puts 'standalone query = '+destinloc[0].tiploc.tps_description
#puts 'integrated query = '+destinloca.tiploc.tps_description
=end
         origin_name = 'nil'
         destin_name = 'nil'

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
         #else
         #   puts 'catch exceptions where there is no match'
         end         
        timetable_hash = {}
         timetable_hash['tiploc_code'] = schedule[:obj].tiploc_code
         timetable_hash['station_name'] = schedule[:obj].tiploc.tps_description
         timetable_hash['platform'] = schedule[:obj].platform
         #timetable_hash['origin_name'] = originloc[0].tiploc.tps_description
         #timetable_hash['destination_name'] = destinloc[0].tiploc.tps_description
         timetable_hash['origin_name'] = origin_name
         timetable_hash['destination_name'] = destin_name         
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
