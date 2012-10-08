#!/usr/bin/env ruby

###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Jul 2012
# Parses the live train movement feed from network rail
#   and updates a station departures table
###########################################################

require 'rubygems'
require 'eventmachine'
require 'json'

require 'yaml'
require "pg"
require "date"

require 'redis'



STDOUT.sync = true 

# get all our cmd line params
@environment 
@quiet    
@host 
@port 
@dbname 
@dbusername 
@dbuserpwd 
@networkrail_feedurl 
@networkrail_login 
@networkrail_passcode   
@error_msg_recipient_email

# direct DB connection
@conn
# stores the current msg - for debug diagnostics
@current_msg

# stores the time we last received a msg from network rail
@timelastmsg

#
@redis


# open the DB connection
def open_db_connection(host, dbname, port, username, pwd)
   # Connection to rails DB
   @conn = PGconn.open(:host=> host, :user => username, :password => pwd, :dbname => dbname, :port => port)
   puts Time.now.to_s+': connected to DB' unless @quiet
end

# close the DB connection TODO case for closing this?
def close_db_connection()
   @conn.finish
end

# convert a unix timestamp in msecs to a ruby time
def unix_timestamp_to_time(unix_timestamp)
   return nil if unix_timestamp.nil?
   return Time.at((unix_timestamp.to_i/1000)).utc   
end

# extract a 'hhmm ' string from a ruby date
# the space is significant. The departure field of the locations table stores 
# times in a 'hhmm ' format
def date_to_hhmm(date)
   return nil if date.nil?
   hh =  date.hour.to_s
   hh = '0'+hh if hh.length==1
   mm = date.min.to_s 
   mm = '0'+mm if mm.length==1
   hhmm = hh+mm+' '
   return hhmm
end

# Calculates a predicted arrival / departure time as a utc ruby timestamp
#   planned_time - planned time as utc
#   secs_offset - the known secs offset from planned. - is ahead of schedule. + is behind schedule
#   allow_predicted_before_planned - whether we are allowing predicted times to be in advance of planned
#                                    whilst a train may arrive early, it should never to depart early
#   return the predicted time  as a utc ruby timestamp
def calculate_predicted_time(planned_time, secs_offset, allow_predicted_before_planned)
   # if train is on time, return planned   
   if secs_offset==0
      return planned_time
   # if train is ontime/early AND we are forcing predicted to not stray behind planned, then return planned time 
   elsif (allow_predicted_before_planned == false && secs_offset<=0)
      return planned_time
   else
      # get planned_time as a ruby Time
      predicted_time = planned_time + secs_offset
      return Time.at((predicted_time.to_f / 60.0).round * 60).utc
   end   
end


# prepare DB queries
def prepare_queries()

   # get basic_schedule uuid for an activation msg
   get_basic_schedule_uuid_for_activation_msg_sql = "
   SELECT uuid, atoc_code FROM basic_schedules JOIN locations ON locations.basic_schedule_uuid = basic_schedules.uuid WHERE basic_schedules.runs_from = $1 AND basic_schedules.service_code like $2 AND locations.departure like $3 AND location_type = 'LO'"
   @conn.prepare("get_basic_schedule_uuid_for_activation_msg_plan", get_basic_schedule_uuid_for_activation_msg_sql)

   # find matching tracked trains by train_id
   get_matching_tracked_train_by_trainid_sql = "SELECT * FROM tracked_trains WHERE train_id =$1"
   @conn.prepare("get_matching_tracked_train_by_trainid_plan", get_matching_tracked_train_by_trainid_sql)

   # get a schedule's origin name
   get_schedules_origin_name_sql = "select tps_description from locations join tiplocs on locations.tiploc_code = tiplocs.tiploc_code where basic_schedule_uuid = $1 and location_type = 'LO'"
   @conn.prepare("get_schedules_origin_name_plan", get_schedules_origin_name_sql)

   # get a schedule's destination name
   get_schedules_destination_name_sql = "select tps_description from locations join tiplocs on locations.tiploc_code = tiplocs.tiploc_code where basic_schedule_uuid = $1 and location_type = 'LT'"
   @conn.prepare("get_schedules_destination_name_plan", get_schedules_destination_name_sql)
         
   # store an activation msg in tracked_trains table   
   store_activation_msg_sql = "INSERT INTO tracked_trains (msg_type,
   schedule_source, train_file_address, schedule_end_date, train_id, tp_origin_timestamp, 
   creation_timestamp, tp_origin_stanox, origin_dep_timestamp, train_service_code, toc_id,
   d1266_record_number, train_call_type, train_uid, train_call_mode, schedule_type, 
   sched_origin_stanox, schedule_wtt_id , schedule_start_date, origin_dep_hhmm, 
   basic_schedule_uuid, origin_name, destination_name, atoc_code,
   created_at, updated_at) 
   VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26)"
   @conn.prepare("store_activation_msg_plan", store_activation_msg_sql)

   # remove all refs to this train in station_updates table
   remove_all_trackedtrains_for_trainid_sql = "DELETE FROM tracked_trains WHERE train_id=$1"
   @conn.prepare("remove_all_trackedtrains_for_trainid_plan", remove_all_trackedtrains_for_trainid_sql)

   # remove all refs to this train in station_updates table
   remove_all_stationupdates_for_trainid_sql = "DELETE FROM station_updates WHERE train_id=$1"
   @conn.prepare("remove_all_stationupdates_for_trainid_plan", remove_all_stationupdates_for_trainid_sql)

   # store a station_update, for stations downstream of the tiploc associated with a train movement
   insert_stationupdate_sql = "INSERT INTO station_updates (tiploc_code, location_type, platform,  train_id,
     diff_from_timetable_secs,  planned_arrival_timestamp, predicted_arrival_timestamp,  planned_departure_timestamp,  predicted_departure_timestamp,  event_type,  
     planned_event_type, variation_status, created_at, updated_at) 
   VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)"
   @conn.prepare("insert_stationupdate_plan", insert_stationupdate_sql)

   # find tiploc / location pair for a given from stanox and basic_schedule_uuid
   # note that this may find multiple  tiploc / location pairs for cases where a single stanox spans multiple tiplocs
   tiploclocation_from_stanox_sql = "select * from locations join tiplocs on locations.tiploc_code = tiplocs.tiploc_code where tiplocs.stanox = $1 and locations.basic_schedule_uuid = $2 order by seq"
   @conn.prepare("tiploclocation_from_stanox_plan", tiploclocation_from_stanox_sql)
   
   # find all downstream stations based on basic_schedule_uuid and seq number of current (exclusive of current)
   find_downstream_locations_excl_sql = "select * from locations where basic_schedule_uuid = $1 and seq > $2 and (public_arrival is not null or public_departure is not null) order by seq"
   @conn.prepare("find_downstream_locations_excl_plan", find_downstream_locations_excl_sql)

end

# cache a msg
def redis_store_msg(msg_type, indiv_msg)
   redis_key=  'msg:'+msg_type.to_s+ ':train_id:'+indiv_msg['body']['train_id'].to_s
   @redis[redis_key] = indiv_msg.to_json   
   puts Time.now.to_s+' stored msg to redis with key = '+redis_key.to_s  unless @quiet      

end

# get a messages, by type
def redis_get_msg(msg_type, train_id)
   redis_key=  'msg:'+msg_type.to_s+ ':train_id:'+train_id.to_s
   retrieved_msg_json = @redis[redis_key]
   if retrieved_msg_json.nil?
      puts Time.now.to_s+' no msg has key = '+redis_key.to_s  unless @quiet     
      return nil 
   else
      puts Time.now.to_s+' we have a msg with key = '+redis_key.to_s  unless @quiet     
      retrieved_msg_hash = JSON.parse(retrieved_msg_json)
      return retrieved_msg_hash
   end
   
end



# process the 0001 activation message
def process_activation_msg(indiv_msg)
    puts Time.now.to_s+' (thread=)'+Thread.current.to_s+': -----------0001 msg start--------------'  unless @quiet


   # get / process the fields of the activation msg       
   toc_id = indiv_msg['body']['toc_id']     
   msg_type = indiv_msg['header']['msg_type']
   train_id = indiv_msg['body']['train_id']                     

   schedule_source = indiv_msg['body']['schedule_source']     
   train_file_address = indiv_msg['body']['train_file_address']     
   schedule_end_date = indiv_msg['body']['schedule_end_date']     
   tp_origin_timestamp = indiv_msg['body']['tp_origin_timestamp']     
   # get creation timestamp                     
   creation_unixtimestamp = indiv_msg['body']['creation_timestamp']     
   creation_timestamp = unix_timestamp_to_time(creation_unixtimestamp)
   tp_origin_stanox = indiv_msg['body']['tp_origin_stanox']     
   # get origin departure timestamp                     
   origin_dep_unixtimestamp = indiv_msg['body']['origin_dep_timestamp']     
   origin_dep_timestamp = unix_timestamp_to_time(origin_dep_unixtimestamp)
   train_service_code = indiv_msg['body']['train_service_code']     
   d1266_record_number = indiv_msg['body']['d1266_record_number']     
   train_call_type = indiv_msg['body']['train_call_type']     
   train_uid = indiv_msg['body']['train_uid']     
   train_call_mode = indiv_msg['body']['train_call_mode']     
   schedule_type = indiv_msg['body']['schedule_type']     
   sched_origin_stanox = indiv_msg['body']['sched_origin_stanox']     
   schedule_wtt_id = indiv_msg['body']['schedule_wtt_id']     
   schedule_start_date = indiv_msg['body']['schedule_start_date'] 

   # get/store the departure time in the format hhmm
   origin_dep_hhmm = date_to_hhmm(origin_dep_timestamp)

   # get the get_basic_schedule_uuid that matches this activation msg
   matching_uuid_res = @conn.exec_prepared("get_basic_schedule_uuid_for_activation_msg_plan", [schedule_start_date, train_service_code, origin_dep_hhmm]) 
   n_matching_uuids = matching_uuid_res.count
   
   # there should be one matching code, else we have a problem
   if n_matching_uuids==1
      basic_schedule_uuid = matching_uuid_res[0]['uuid']
      atoc_code = matching_uuid_res[0]['atoc_code']

      # get the destination name 
      resdest = @conn.exec_prepared("get_schedules_destination_name_plan", [basic_schedule_uuid]) 
      destname = resdest[0]['tps_description']
            
      # get the origin name 
      resorigin = @conn.exec_prepared("get_schedules_origin_name_plan", [basic_schedule_uuid]) 
      originname = resorigin[0]['tps_description']

      # insert into tracking table
      res = @conn.exec_prepared("store_activation_msg_plan", [msg_type, schedule_source, train_file_address, schedule_end_date, train_id, tp_origin_timestamp, 
      creation_timestamp, tp_origin_stanox, origin_dep_timestamp, train_service_code, toc_id, d1266_record_number, 
      train_call_type, train_uid, train_call_mode, schedule_type, sched_origin_stanox, schedule_wtt_id,  schedule_start_date, origin_dep_hhmm, 
      basic_schedule_uuid, originname, destname, atoc_code, Time.new, Time.new]) 
      puts Time.now.to_s+': 0001 msg - now tracking train_id '+train_id+''        unless @quiet                 
      
      # get the day that this event was supposed to occur
      planned_update_event_day= Date.new(origin_dep_timestamp.year, origin_dep_timestamp.month, origin_dep_timestamp.mday)

      # update downstream stations with 'no report?'
      # find / update downstream stations, and add to station_updates
      downstream_locations = @conn.exec_prepared("find_downstream_locations_excl_plan", [basic_schedule_uuid, 1]) 
      downstream_locations.each { |downstream_location| 

         tiploc = downstream_location['tiploc_code']
         
         # get planned arrival / departure as full timestamps
         unless downstream_location['public_arrival'].nil?
            planned_arrival_hhmm = downstream_location['public_arrival'].strip
            planned_ds_arrival_day = planned_update_event_day
            planned_ds_arrival_day +=1 if downstream_location['next_day_arrival'] =~ (/(true|t|yes|y|1)$/i)               
            planned_arrival_ts = Time.utc(planned_ds_arrival_day.year,planned_ds_arrival_day.month,planned_ds_arrival_day.day,planned_arrival_hhmm[0,2].to_i,  planned_arrival_hhmm[2,2].to_i)               
            #predicted_arrival_ts = calculate_predicted_time(planned_arrival_ts, diff_from_timetable_secs,true)
         end
         unless downstream_location['public_departure'].nil?
            planned_departure_hhmm = downstream_location['public_departure'].strip 
            planned_ds_departure_day = planned_update_event_day
            planned_ds_departure_day +=1 if downstream_location['next_day_departure'] =~ (/(true|t|yes|y|1)$/i)               
            planned_departure_ts = Time.utc(planned_ds_departure_day.year,planned_ds_departure_day.month,planned_ds_departure_day.day,planned_departure_hhmm[0,2].to_i,  planned_departure_hhmm[2,2].to_i)               
            #predicted_departure_ts = calculate_predicted_time(planned_departure_ts, diff_from_timetable_secs,false)
         end
         
         @conn.exec_prepared("insert_stationupdate_plan", 
         [tiploc, downstream_location['location_type'], downstream_location['platform'], train_id, 
         0, planned_arrival_ts, nil, planned_departure_ts, nil, 'ACTIVATION', 
         nil, 'NO REPORT', Time.new, Time.new])                       
      }
      puts Time.now.to_s+': updated = '+downstream_locations.count.to_s+' stations with an activation msg' unless @quiet
   elsif  n_matching_uuids==0
      puts Time.now.to_s+': PROBLEM: no matching basic_schedule_uuid for schedule_start_date='+schedule_start_date+' train_service_code ='+train_service_code+' origin_dep_hhmm = '+origin_dep_hhmm+'' 
      p indiv_msg
      puts '-------'
   else
      # TODO these can be distinguished by the origin tiploc in timetables??
      puts Time.now.to_s+': PROBLEM: multiple matching basic_schedule_uuid for schedule_start_date='+schedule_start_date+' train_service_code ='+train_service_code+' origin_dep_hhmm = '+origin_dep_hhmm+'' 
      p indiv_msg
      puts '-------'
   end
   puts Time.now.to_s+' (thread=)'+Thread.current.to_s+': -----------0001 msg end--------------' unless @quiet
   #
   #  process downstream stations: as no report and empty predicted text ? 
end

# process the 0002 cancellation message
def process_cancellation_msg(indiv_msg, tracked_train)

   puts Time.now.to_s+': -----------0002 msg start--------------' unless @quiet
   puts Time.now.to_s+': its a 0002 msg....' unless @quiet
   p indiv_msg unless @quiet

   basic_schedule_uuid = tracked_train['basic_schedule_uuid']

   # get / process the fields of the activation msg       
   msg_type = indiv_msg['header']['msg_type']      
   train_id = indiv_msg['body']['train_id']                     

   train_file_address = indiv_msg['body']['train_file_address'] 
   train_service_code = indiv_msg['body']['train_service_code'] 
   orig_loc_stanox = indiv_msg['body']['orig_loc_stanox'] 
   toc_id = indiv_msg['body']['toc_id'] 
   dep_unixtimestamp = indiv_msg['body']['dep_timestamp']                            
   dep_timestamp = unix_timestamp_to_time(dep_unixtimestamp)
   division_code = indiv_msg['body']['division_code'] 
   loc_stanox = indiv_msg['body']['loc_stanox'] 
   canx_unixtimestamp = indiv_msg['body']['canx_timestamp'] 
   canx_timestamp = unix_timestamp_to_time(canx_unixtimestamp)
   canx_reason_code = indiv_msg['body']['canx_reason_code'] 
   orig_loc_unixtimestamp = indiv_msg['body']['orig_loc_timestamp'] 
   orig_loc_timestamp = unix_timestamp_to_time(orig_loc_unixtimestamp)
   canx_type = indiv_msg['body']['canx_type'] 

   # cancelled train - get rid of all references to it
   # remove all refs to this train in station_updates table
   @conn.exec_prepared("remove_all_stationupdates_for_trainid_plan", [train_id]) 
   # remove all refs to this train in tracked trains table
   @conn.exec_prepared("remove_all_trackedtrains_for_trainid_plan", [train_id]) 
   
   #res = @conn.exec_prepared("insert_0002_msg_plan", [msg_type, train_file_address, train_service_code, orig_loc_stanox, toc_id, dep_timestamp, division_code, loc_stanox, canx_timestamp, canx_reason_code, train_id, orig_loc_timestamp, canx_type, basic_schedule_uuid, Time.new, Time.new]) 
   puts Time.now.to_s+': -----------0002 msg end--------------' #unless @quiet

end



# process the 0003 Train Movement message
def process_trainmovement_msg(indiv_msg, tracked_train)

   #puts Time.now.to_s+': -----------0003 msg start--------------' unless @quiet
   
   # get the schedule UUID
   basic_schedule_uuid = tracked_train['basic_schedule_uuid']            

   # get the individual msg components   
   msg_type = indiv_msg['header']['msg_type']      
   train_id = indiv_msg['body']['train_id']                     
   event_type  = indiv_msg['body']['event_type']
   gbtt_unixtimestamp  = indiv_msg['body']['gbtt_timestamp']
   gbtt_timestamp = unix_timestamp_to_time(gbtt_unixtimestamp)    
   original_loc_stanox = indiv_msg['body']['original_loc_stanox']                           
   planned_unixtimestamp = indiv_msg['body']['planned_timestamp']
   planned_timestamp = unix_timestamp_to_time(planned_unixtimestamp)   
   timetable_variation = nil                        
   timetable_variation = indiv_msg['body']['timetable_variation'] unless indiv_msg['body']['timetable_variation']==''                          
   original_loc_unixtimestamp = indiv_msg['body']['original_loc_timestamp']
   original_loc_timestamp = unix_timestamp_to_time(original_loc_unixtimestamp)                                                      
   current_train_id = indiv_msg['body']['current_train_id']
   delay_monitoring_point = indiv_msg['body']['delay_monitoring_point']
   next_report_run_time = nil                        
   next_report_run_time = indiv_msg['body']['next_report_run_time'] unless indiv_msg['body']['next_report_run_time']==''                          
   reporting_stanox = indiv_msg['body']['reporting_stanox']                           
   actual_unixtimestamp = indiv_msg['body']['actual_timestamp']
   actual_timestamp = unix_timestamp_to_time(actual_unixtimestamp)                                                      
   correction_ind = indiv_msg['body']['correction_ind']
   event_source = indiv_msg['body']['event_source']
   train_file_address = indiv_msg['body']['train_file_address']
   platform = indiv_msg['body']['platform']
   division_code = indiv_msg['body']['division_code']
   train_terminated = indiv_msg['body']['train_terminated']
   offroute_ind = indiv_msg['body']['offroute_ind']
   variation_status = indiv_msg['body']['variation_status']
   train_service_code = indiv_msg['body']['train_service_code']
   toc_id = indiv_msg['body']['toc_id']
   loc_stanox = indiv_msg['body']['loc_stanox']
   auto_expected = indiv_msg['body']['auto_expected']
   direction_ind = indiv_msg['body']['direction_ind']                           
   route = nil                        
   route = indiv_msg['body']['route'] unless indiv_msg['body']['route']==''                          
   planned_event_type = indiv_msg['body']['planned_event_type']
   next_report_stanox = indiv_msg['body']['next_report_stanox']
   line_ind   = indiv_msg['body']['line_ind']
   #res = @conn.exec_prepared("insert_0003_msg_plan", [msg_type, event_type, gbtt_timestamp, original_loc_stanox, planned_timestamp, timetable_variation, original_loc_timestamp, current_train_id, delay_monitoring_point, next_report_run_time, reporting_stanox, actual_timestamp, correction_ind, event_source, train_file_address, platform, division_code, train_terminated, train_id, offroute_ind, variation_status, train_service_code, toc_id, loc_stanox, auto_expected, direction_ind, route, planned_event_type, next_report_stanox, line_ind, basic_schedule_uuid, Time.new, Time.new]) 

   # calc the n secs delay
   # negative values are early, positive values are late.
   diff_from_timetable_secs = actual_timestamp -planned_timestamp
   diff_from_timetable_mins = (diff_from_timetable_secs / 60.0).round

   # TODO perform this as a single transaction
   # remove all refs to this train in station_updates table
   @conn.exec_prepared("remove_all_stationupdates_for_trainid_plan", [train_id]) 

   # record if this journey is over or not
   journey_complete = false

   # various cases can trigger a journey to be complete
   if train_terminated == 'true' || event_type == 'DESTINATION' || planned_event_type == 'DESTINATION'
      journey_complete
   end                        

   # if journey is complete, remove all refs to this train in tracked trains table, and quit this method
   if journey_complete
      @conn.exec_prepared("remove_all_trackedtrains_for_trainid_plan", [train_id]) 
      puts Time.now.to_s+': train is terminated, so flushing from station_updates and not adding any more info ' unless @quiet
      return
   end                        

   # find current tiploc and location
   tiploclocation_res = @conn.exec_prepared("tiploclocation_from_stanox_plan", [loc_stanox, basic_schedule_uuid]) 
   n_matching_tiploclocations = tiploclocation_res.count
   focal_scheduled_location=nil
   # check the n tiploc/location paris we have. Zero is a problem and we can't update. But we can handle the one or more case
   if n_matching_tiploclocations ==0
      puts Time.now.to_s+': PROBLEM: combination of stanox '+loc_stanox.to_s+' and basic_schedule_uuid '+basic_schedule_uuid+' matches '+n_matching_tiploclocations.to_s + ' tiplocs/locations'
   elsif n_matching_tiploclocations ==1
      focal_scheduled_location = tiploclocation_res[0]
   else
      #   use first for an arrival event, otherwise last?
      if event_type == 'ARRIVAL'
         focal_scheduled_location = tiploclocation_res[0]
      else
         focal_scheduled_location = tiploclocation_res[n_matching_tiploclocations-1]
      end
   end

   # get the day that this event was supposed to occur
   planned_update_event_day= Date.new(planned_timestamp.year, planned_timestamp.month, planned_timestamp.mday)

   # if we have identified the trains location within the schedule
   unless focal_scheduled_location.nil?   
   
      originame = tracked_train['origin_name']
      destname = tracked_train['destination_name']
      toc_id = tracked_train['toc_id']
      atoc_code = tracked_train['atoc_code']
      train_service_code = tracked_train['train_service_code']

      loc_tiploc = focal_scheduled_location['tiploc_code']
      loc_seq =focal_scheduled_location['seq']
      
      # track how many days ahead of the planned update date we are, as we traverse route with updates
      ndays_advanced = 0
      
      # get the downstream stations...
      # find / update downstream stations, and add to station_updates
      downstream_locations = @conn.exec_prepared("find_downstream_locations_excl_plan", [basic_schedule_uuid, loc_seq]) 
      downstream_locations.each { |downstream_location| 
                  
         tiploc = downstream_location['tiploc_code']
         # get planned arrival / departure as full timestamps
         unless downstream_location['public_arrival'].nil?
            planned_arrival_hhmm = downstream_location['public_arrival'].strip
            planned_ds_arrival_day = planned_update_event_day
            planned_ds_arrival_day +=1 if downstream_location['next_day_arrival'] =~ (/(true|t|yes|y|1)$/i)               
            planned_arrival_ts = Time.utc(planned_ds_arrival_day.year,planned_ds_arrival_day.month,planned_ds_arrival_day.day,planned_arrival_hhmm[0,2].to_i,  planned_arrival_hhmm[2,2].to_i)               
            predicted_arrival_ts = calculate_predicted_time(planned_arrival_ts, diff_from_timetable_secs,true)
         end
         unless downstream_location['public_departure'].nil?
            planned_departure_hhmm = downstream_location['public_departure'].strip 
            planned_ds_departure_day = planned_update_event_day
            planned_ds_departure_day +=1 if downstream_location['next_day_departure'] =~ (/(true|t|yes|y|1)$/i)               
            planned_departure_ts = Time.utc(planned_ds_departure_day.year,planned_ds_departure_day.month,planned_ds_departure_day.day,planned_departure_hhmm[0,2].to_i,  planned_departure_hhmm[2,2].to_i)               
            predicted_departure_ts = calculate_predicted_time(planned_departure_ts, diff_from_timetable_secs,false)
         end
         
         @conn.exec_prepared("insert_stationupdate_plan", 
         [tiploc, downstream_location['location_type'], downstream_location['platform'], train_id, 
         diff_from_timetable_secs.to_i, planned_arrival_ts, predicted_arrival_ts, planned_departure_ts, predicted_departure_ts, event_type, planned_event_type, 
         variation_status, Time.new, Time.new])                       
      }
      
      # for the arrival case, update the current tiploc appropriately
      if event_type == 'ARRIVAL'      
         # get planned arrival / departure as full timestamps
         unless focal_scheduled_location['public_arrival'].nil?
            planned_arrival_hhmm = focal_scheduled_location['public_arrival'].strip
            planned_ds_arrival_day = planned_update_event_day
            planned_ds_arrival_day +=1 if focal_scheduled_location['next_day_arrival'] =~ (/(true|t|yes|y|1)$/i)               
            planned_arrival_ts = Time.utc(planned_ds_arrival_day.year,planned_ds_arrival_day.month,planned_ds_arrival_day.day,planned_arrival_hhmm[0,2].to_i,  planned_arrival_hhmm[2,2].to_i)               
            predicted_arrival_ts = calculate_predicted_time(planned_arrival_ts, diff_from_timetable_secs,true)
         end
         unless focal_scheduled_location['public_departure'].nil?
            planned_departure_hhmm = focal_scheduled_location['public_departure'].strip 
            planned_ds_departure_day = planned_update_event_day
            planned_ds_departure_day +=1 if focal_scheduled_location['next_day_departure'] =~ (/(true|t|yes|y|1)$/i)               
            planned_departure_ts = Time.utc(planned_ds_departure_day.year,planned_ds_departure_day.month,planned_ds_departure_day.day,planned_departure_hhmm[0,2].to_i,  planned_departure_hhmm[2,2].to_i)               
            predicted_departure_ts = calculate_predicted_time(planned_departure_ts, diff_from_timetable_secs,false)
         end

         @conn.exec_prepared("insert_stationupdate_plan", 
         [loc_tiploc, focal_scheduled_location['location_type'], 
         focal_scheduled_location['platform'], train_id, 
         diff_from_timetable_secs.to_i, planned_arrival_ts, predicted_arrival_ts, planned_departure_ts, predicted_departure_ts, 
         event_type, planned_event_type, 'ARRIVED', Time.new, Time.new])                          
       
      end

   else
      puts Time.now.to_s+': not able to update station_updates table' unless @quiet
   end                              
   #puts Time.now.to_s+': -----------0003 msg end--------------' unless @quiet

end

# process the 0004 Unidentified Train message
# can't do anything with this...
def process_unidentifiedtrain_msg(indiv_msg, tracked_train)

   puts Time.now.to_s+': -----------0004 msg start--------------' #unless @quiet
   puts Time.now.to_s+': its a 0004 msg....' #unless @quiet
   p indiv_msg #unless @quiet

   basic_schedule_uuid = tracked_train['basic_schedule_uuid']
   
   puts Time.now.to_s+': -----------0004 msg end--------------' #unless @quiet
end 

# process the 0005 Train Reinstatement message
# ?
def process_trainreinstatement_msg(indiv_msg, tracked_train)
   puts Time.now.to_s+': -----------0005 msg start--------------' #unless @quiet
   puts Time.now.to_s+': its a 0005 msg....' #unless @quiet
   p indiv_msg #unless @quiet

   basic_schedule_uuid = tracked_train['basic_schedule_uuid']
   
   train_id  = indiv_msg['body']['train_id']
   puts Time.now.to_s+': the train_id '+train_id+' relates to basic_schedule_uuid '+basic_schedule_uuid+' so we can ref with timetables'   unless @quiet
   puts Time.now.to_s+': -----------0005 msg end--------------' #unless @quiet

end        

# process the 0006 Train Change of Origin
# ?
def process_trainchangeoforigin_msg(indiv_msg, tracked_train)
   puts Time.now.to_s+': -----------0006 msg start--------------' #unless @quiet
   puts Time.now.to_s+': its a 0006 msg....' #unless @quiet
   p indiv_msg #unless @quiet
   
   basic_schedule_uuid = tracked_train['basic_schedule_uuid']
      
   train_id = indiv_msg['body']['train_id']
   puts Time.now.to_s+': the train_id '+train_id+' relates to basic_schedule_uuid '+basic_schedule_uuid+' so we can ref with timetables'           unless @quiet                                      
   puts Time.now.to_s+': -----------0006 msg end--------------' #unless @quiet

end

# process the 0007 Train Change of Identity message
# update the train id in trust_feed, tracked_trains and station_updates
def process_trainchangeofidentify_msg(indiv_msg, tracked_train)
   puts Time.now.to_s+': -----------0007 msg start--------------' #unless @quiet
   puts Time.now.to_s+': its a 0007 msg....' #unless @quiet
   p indiv_msg #unless @quiet

   basic_schedule_uuid = tracked_train['basic_schedule_uuid']
   train_id  = indiv_msg['body']['train_id']
   puts Time.now.to_s+': the train_id '+train_id+' relates to basic_schedule_uuid '+basic_schedule_uuid+' so we can ref with timetables'        unless @quiet                                          unless @quiet

   puts Time.now.to_s+': -----------0007 msg end--------------' #unless @quiet

end

# process the 0008 Train Change of Location message
def process_trainchangeoflocation_msg(indiv_msg, tracked_train)
   puts Time.now.to_s+': -----------0008 msg start--------------' #unless @quiet
   puts Time.now.to_s+': its a 0008 msg....' #unless @quiet
   p indiv_msg #unless @quiet

   train_id  = indiv_msg['body']['train_id']
   puts Time.now.to_s+': the train_id '+train_id+' relates to basic_schedule_uuid '+tracked_train['basic_schedule_uuid']+' so we can ref with timetables'                                                 unless @quiet
   
   puts Time.now.to_s+': -----------0008 msg end--------------' #unless @quiet

end

# a dummy method - can we keep up, when we do no processing at all, but wait for 60 secs
def sleep60()
   sleep(60)
end

module Poller

   include EM::Protocols::Stomp

   # initialisation steps once we have a connection to apachemq feed
   def connection_completed
      
      @environment = ARGV[0]
      @quiet = false      
      @quiet = true if ARGV[1].downcase == 'quiet'
      @host = ARGV[2]
      @port = ARGV[3]
      @dbname = ARGV[4]
      @dbusername = ARGV[5]
      @dbuserpwd = ARGV[6]
      @networkrail_login = ARGV[8]
      @networkrail_passcode = ARGV[9] 
      @error_msg_recipient_email = ARGV[10] 
      subscribed_feeds_string = ARGV[11] 
      @subscribed_feeds = subscribed_feeds_string.split(',')
      
      @redis = Redis.new



      open_db_connection(@host, @dbname, @port, @dbusername, @dbuserpwd)      
      # prep our SQL queries
      prepare_queries()     

      # authent / connect to feed - credentials loaded from a yml
      networkrail_login = 'david.mountain@placr.co.uk'
      networkrail_passcode = 'Thentherewere3;'
      puts Time.now.to_s+': connecting to feed' unless @quiet
      connect :login => @networkrail_login, :passcode => @networkrail_passcode
      puts Time.now.to_s+': connected to feed' unless @quiet

   end

   def receive_msg msg
      Thread.current.priority = Thread.current.priority+1
      puts Time.now.to_s+':Thread.current.priority = '+Thread.current.priority.to_s unless @quiet
   
     puts Time.now.to_s+': msg received' unless @quiet
      
      if msg.command == "CONNECTED"

         puts Time.now.to_s+': got connected - subscribing' unless @quiet

         @subscribed_feeds.each do |subscribed_feed|
            puts 'subscribing to '+subscribed_feed.to_s
            subscribe subscribed_feed.to_s
         end
#subscribe '/topic/TRAIN_MVT_EK_TOC'    # train movements - London

# TODO subscribe
# TODO try connecting to all?
# Tests: for bottle neck
# London OG feed: London OG timetables (works)
# All TOCS  feed: London OG timetables (?)
# London OG feed: All TOCs  timetables (?)
# All TOCs  feed: All TOCS  timetables (?)
#         subscribe '/topic/TRAIN_MVT_ALL_TOC'  # train movements - all TOCs
#         subscribe '/topic/TRAIN_MVT_EK_TOC'    # train movements - TFL only
#         subscribe '/topic/TD_ALL_SIG_AREA'
#         subscribe '/topic/VSTP_ALL'
#         subscribe '/topic/TSR_ALL_ROUTE'
#         subscribe '/topic/RTPPM_ALL'


      else


         # any exceptions in this loop are caught and shouldn't stop the script functioning
         begin

            msg_list = JSON.parse(msg.body)
#            if msg.header['destination'] ==   '/topic/TRAIN_MVT_ALL_TOC' || msg.header['destination'] ==   '/topic/TRAIN_MVT_EK_TOC'
               msg_list.each do |indiv_msg|
               
                  # store the current msg for debug diagnostics
                  @current_msg = indiv_msg
                  toc_id = indiv_msg['body']['toc_id']     
#                  if toc_id == '30'
                  
                     msg_type = indiv_msg['header']['msg_type']
                     puts Time.now.to_s+' (thread='+Thread.current.to_s+'): got a '+msg_type.to_s+' msg to process' unless @quiet

#                     unless msg_type == '0003' # spare the log
#                        puts Time.now.to_s+': got a '+msg_type.to_s+' msg to process' unless @quiet
#                     end
                     
=begin
# check if already stored...                     
# cache a msg
#def redis_store_msg(msg_type, indiv_msg)
   redis_key=  'msg:'+msg_type.to_s+ ':train_id:'+indiv_msg['body']['train_id'].to_s
#   puts Time.now.to_s+' caching pair with key '+redis_key.to_s  unless @quiet   
   @redis[redis_key] = indiv_msg.to_json   
   puts Time.now.to_s+' stored msg to redis with key = '+redis_key.to_s  unless @quiet      

#   retrieved_msg_json = @redis[redis_key]
#   retrieved_msg_hash = JSON.parse(retrieved_msg_json)
#   retrieved_train_id = retrieved_msg_hash['body']['train_id'].to_s
#   puts Time.now.to_s+' train_id = '+retrieved_train_id.to_s  unless @quiet      
end

# get a messages, by type
def redis_get_msg(msg_type, train_id)
   redis_key=  'msg:'+msg_type.to_s+ ':tr
=end   
                     
                     
                     # redis cache
                     #puts 'msg_type = '+msg_type.to_s
                     #puts 'indiv_msg = '
                     #p indiv_msg
                     # are we tracking this msg?
                     # get a messages, by type
=begin                     
                     train_id = indiv_msg['body']['train_id']   
                     puts Time.now.to_s+' (thread='+Thread.current.to_s+'): train_id '+train_id.to_s+'' unless @quiet
                     activation_msg = redis_get_msg('0001', train_id)
                     if activation_msg.nil?
                        puts Time.now.to_s+': not tracked' unless @quiet                        
                     else                     
                        puts Time.now.to_s+': we are tracking' unless @quiet                        
                     end
                     #puts Time.now.to_s+' (thread='+Thread.current.to_s+'): activation_msg '+activation_msg.to_s+' ' unless @quiet

                     # store this msg
                     redis_store_msg(msg_type, indiv_msg)
=end                     

                     # if its not an activation msgs, are we tracking it
                     #if msg_type != '0001'                     
                     #   puts Time.now.to_s+' not an activation msg'  unless @quiet
                     #end

                     # get the train id from the msg, and check if it has been initialised by a 0001 msg
                     #train_id = indiv_msg['body']['train_id']                     
                     #matching_trackedtrains_res =  @conn.exec_prepared("get_matching_tracked_train_by_trainid_plan", [train_id])     

                     # get the train id from the msg, and check if it has been initialised by a 0001 msg
                     train_id = indiv_msg['body']['train_id']                     
                     matching_trackedtrains_res =  @conn.exec_prepared("get_matching_tracked_train_by_trainid_plan", [train_id])     
                                      
                     # get the basic_schedule_uuid for this 
                     tracked_train=nil
                     if matching_trackedtrains_res.count.to_i==1
                        tracked_train = matching_trackedtrains_res[0]
                        puts Time.now.to_s+': '+train_id.to_s+' is tracked' unless @quiet                        
                     end
                     
                     if matching_trackedtrains_res.count.to_i==0
                        puts Time.now.to_s+': '+train_id.to_s+' not tracked' unless @quiet                        
                     end

                     puts Time.now.to_s+': Thread.current.priority = '+Thread.current.priority.to_s unless @quiet

                     # Message 1 – 0001 – Activation Message
                     if msg_type == '0001'                     
                       puts Time.now.to_s+' (thread=)'+Thread.current.to_s+': starting multithread 0001 msg for train_id '+train_id+''                                                
 
                        # if we are not already tracking this train, insert into tracking table, else report an error
                        if matching_trackedtrains_res.count.to_i == 0
                           puts Time.now.to_s+': about to run '+train_id+''   
                   
                           t=Thread.new{process_activation_msg(indiv_msg) }
                           puts Time.now.to_s+': t.priority = '+t.priority.to_s unless @quiet
                           #t=Thread.new{sleep60() }
                           #process_activation_msg(indiv_msg)   
                        else
                           puts Time.now.to_s+': PROBLEM!'                                                
                           puts Time.now.to_s+': we have a new 0001 msg for train_id '+train_id+' but we are lready tracking it'                                                
                        end       
                       puts Time.now.to_s+' (thread=)'+Thread.current.to_s+': finished multithread 0001 msg for train_id '+train_id+''                                                
 
                     end
                     
                     # Message 2 – 0002 – Cancellation
                     if msg_type == '0002'
                        if tracked_train.nil?
                           puts Time.now.to_s+": the train_id "+train_id+" has not been activated, so we can't xref with timetables"    unless @quiet                     
                           p indiv_msg
                           p '------'
                        else
                           #process_cancellation_msg(indiv_msg, tracked_train)      
                           t=Thread.new{sleep60() }
                           puts Time.now.to_s+': t.priority = '+t.priority.to_s unless @quiet
                        end
                     end
                     # Message 3 – 0003 – Train Movement
                     if msg_type == '0003'
                        if tracked_train.nil?
                           puts Time.now.to_s+": the train_id "+train_id+" has not been activated, so we can't xref with timetables"     unless @quiet                    
                           if train_id[0] == '2'
                              puts Time.now.to_s+": Could be a problem - train_id starts with '2'" 
                              p indiv_msg
                              p '------'
                           else
                              puts Time.now.to_s+": Unlikely to be a problem - train_id doesn't start with '2'"     unless @quiet                    
                           end
                        else
                           #process_trainmovement_msg(indiv_msg, tracked_train)      
                           #t=Thread.new{process_trainmovement_msg(indiv_msg, tracked_train)   }
                           t=Thread.new{sleep60() }
                           puts Time.now.to_s+': t.priority = '+t.priority.to_s unless @quiet
                        end                    
                     end
                     # Message 4 – 0004 – Unidentified Train
                     if msg_type == '0004'
                        if tracked_train.nil?
                           puts Time.now.to_s+": the train_id "+train_id+" has not been activated, so we can't xref with timetables"        unless @quiet                 
                           p indiv_msg
                           p '------'
                        else
#                           process_unidentifiedtrain_msg(indiv_msg, tracked_train)      
                           t=Thread.new{sleep60() }
                        end                    
                     end
                     # Message 5 – 0005 – Train Reinstatement
                     if msg_type == '0005'                     
                        if tracked_train.nil?
                           puts Time.now.to_s+": the train_id "+train_id+" has not been activated, so we can't xref with timetables"    unless @quiet                     
                           p indiv_msg
                           p '------'
                        else
#                           process_trainreinstatement_msg(indiv_msg, tracked_train)      
                           t=Thread.new{sleep60() }
                        end              
                     end
                     # Message 6 – 0006 – Train Change of Origin
                     if msg_type == '0006'
                        if tracked_train.nil?
                           puts Time.now.to_s+": the train_id "+train_id+" has not been activated, so we can't xref with timetables"    unless @quiet                     
                           p indiv_msg
                           p '------'
                        else
#                           process_trainchangeoforigin_msg(indiv_msg, tracked_train)      
                           t=Thread.new{sleep60() }
                        end 
                     end
                     # Message 7 – 0007 – Train Change of Identity
                     if msg_type == '0007'
                        if tracked_train.nil?
                           puts Time.now.to_s+": the train_id "+train_id+" has not been activated, so we can't xref with timetables"    unless @quiet                     
                           p indiv_msg
                           p '------'
                        else
#                           process_trainchangeofidentify_msg(indiv_msg, tracked_train)      
                           t=Thread.new{sleep60() }
                        end                     
                     end
                     # Message 8 – 0008 – Train Change of Location
                     if msg_type == '0008'
                        if tracked_train.nil?
                           puts Time.now.to_s+": the train_id "+train_id+" has not been activated, so we can't xref with timetables"      unless @quiet                   
                           p indiv_msg
                           p '------'
                        else
#                           process_trainchangeoflocation_msg(indiv_msg, tracked_train)      
                           t=Thread.new{sleep60() }
                        end 
                     end
                  #end  # if toc = 30
=begin

=end
               end  #    msg_list.each do |indiv_msg|
            #end # if msg.header['destination'] ==   '/topic/....'
           
         # this 'should' allow the loop to continue, whilst emailing us an alert
         rescue Exception => e
            # log the exception
            puts '==============================================='
            puts 'rescued Exception'
            puts e.message
            puts Time.now.to_s+': @current_msg....'
            p @current_msg            
            # email notice about exception
            emailcontent = 'live feed parser ruby script failed with message' + e.message.to_s
            emailheader = 'live feed parser ruby script failed'
            `#echo #{emailcontent} | mutt -s #{emailheader} #{@error_msg_recipient_email}`
         end # begin / rescue Exception
      end # if / else msg.command == "CONNECTED"
   end #   receive_msg function
end # Poller module


# EventMachine method - initializes and runs an event loop. Method only returns if user-callback code calls stop_event_loop. 
# Here we define our client (Poller) and server (the networkrail datafeed)
EM.run {

   @networkrail_feedurl = ARGV[7]
   puts Time.now.to_s+': @networkrail_feedurl = '+@networkrail_feedurl  unless @quiet
   # EventMachine method - initiates a TCP connection to the remote server and sets up event-handling for the connection
   EM.connect @networkrail_feedurl, 61618, Poller
}


