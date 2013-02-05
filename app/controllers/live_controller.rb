###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Jul 2012
# A live departures controller
###########################################################

require 'json'
#require Rails.root + "lib/performance.rb" # works
#require "lib/performance.rb" # death
#require "performance.rb" # works
require "performance" # works
#require "Performance"#megadeath
#include "Performance"# death

class LiveController < ApplicationController
   

   # a shortterm shortcut to just get performance for a small number of stations
   def london_performance_json_test
      lst_hash = {:lat => 51.517989, :lon => -0.081426, :crs => 'LST', :name => "London Liverpool Street", :avg_secs_late => 30, :sample_size => 12}
      old_hash = {:lat => 51.525830, :lon => -0.088535, :crs => 'OLD', :name => "Old Street", :avg_secs_late => 20, :sample_size => 3}
      performance_array = [lst_hash, old_hash]
      # transform to json, and respond
      output_json = performance_array.to_json
      send_data output_json, :type => "text/plain", :disposition => 'inline'
   end

   # a shortterm shortcut to just get performance for a small number of stations
   def london_performance_json

      performance_array = []

=begin
      # array of stations we wish to get performance stats about
      crs_tiplocs = {
      "LST" => 'LIVST',
      "OLD" => 'OLDST',
      "MOG" => 'MRGT',
      "SDC" => 'SHRDHST',
      "HOX" => 'HOXTON',
      "FST" => 'FENCHRS',
      "CST" => 'CANONST',
      "ZFD" => 'FRNDNLT',
      "BET" => 'BTHNLGR',
      "ZWL" => 'WCHAPEL',
      "CTK" => 'CTMSLNK',
      "BFR" => 'BLFR',
      "HGG" => 'HAGGERS',
      "LBG" => 'LNDNBDG,LNDNBD,LNDNBDE,LNDNBAL,LNDNB9,LNDNB10,LNDNB11,LNDNB12,LNDNB13,LNDNB14,LNDNB1,LNDNB16,LNDN490',
      "CBH" => 'CAMHTH',
      "SDE" => 'SHADWEL',
      "EXR" => 'ESSEXRD',
      "WAE" => 'WLOE',
      "DLJ" => 'DALS',
      "LOF" => 'LONFLDS',
      "WPE" => 'WAPPING',
      "KGX" => 'KNGX',
      "DLK" => 'DALSKLD',
      "WAT" => 'WATRLMN'}
      # array of stations we wish to get performance stats about
      crs_tiplocs = {
      "LST" => {:tiplocs => 'LIVST'},
      "OLD" => {:tiplocs => 'OLDST'}
      }
=end

      crs_tiplocs = {

"LST" => {:lon => -0.081426,:lat => 51.517989,:name=>"London Liverpool Street", :tiplocs =>'LIVST'},
"OLD" => {:lon => -0.088535,:lat => 51.52583,:name=>"Old Street", :tiplocs =>'OLDST'},
"MOG" => {:lon => -0.088943,:lat => 51.51849,:name=>"Moorgate (Great Northern)", :tiplocs =>'MRGT'},
"SDC" => {:lon => -0.075246,:lat => 51.523374,:name=>"Shoreditch High Street", :tiplocs =>'SHRDHST'},
"HOX" => {:lon => -0.075682,:lat => 51.53151,:name=>"Hoxton", :tiplocs =>'HOXTON'},
"FST" => {:lon => -0.078897,:lat => 51.511644,:name=>"London Fenchurch Street", :tiplocs =>'FENCHRS'},
"CST" => {:lon => -0.090293,:lat => 51.511381,:name=>"London Cannon Street", :tiplocs =>'CANONST'},
"ZFD" => {:lon => -0.105205,:lat => 51.520165,:name=>"Farringdon (London)", :tiplocs =>'FRNDNLT'},
"BET" => {:lon => -0.059568,:lat => 51.523916,:name=>"Bethnal Green", :tiplocs =>'BTHNLGR'},
"ZWL" => {:lon => -0.059757,:lat => 51.519467,:name=>"Whitechapel", :tiplocs =>'WCHAPEL'},
"CTK" => {:lon => -0.10359,:lat => 51.513934,:name=>"City Thameslink", :tiplocs =>'CTMSLNK'},
"BFR" => {:lon => -0.103332,:lat => 51.511808,:name=>"London Blackfriars", :tiplocs =>'BLFR'},
"HGG" => {:lon => -0.075667,:lat => 51.538704,:name=>"Haggerston", :tiplocs =>'HAGGERS'},
"LBG" => {:lon => -0.086088,:lat => 51.505107,:name=>"London Bridge", :tiplocs =>'LNDNBDG,LNDNBD,LNDNBDE,LNDNBAL,LNDNB9,LNDNB10,LNDNB11,LNDNB12,LNDNB13,LNDNB14,LNDNB1,LNDNB16,LNDN490'},
"CBH" => {:lon => -0.057279,:lat => 51.531971,:name=>"Cambridge Heath", :tiplocs =>'CAMHTH'},
"SDE" => {:lon => -0.056934,:lat => 51.511282,:name=>"Shadwell", :tiplocs =>'SHADWEL'},
"EXR" => {:lon => -0.096276,:lat => 51.540704,:name=>"Essex Road", :tiplocs =>'ESSEXRD'},
"WAE" => {:lon => -0.108898,:lat => 51.504074,:name=>"London Waterloo", :tiplocs =>'WLOE'},
"DLJ" => {:lon => -0.075138,:lat => 51.546114,:name=>"Dalston Junction", :tiplocs =>'DALS'},
"LOF" => {:lon => -0.057753,:lat => 51.541151,:name=>"London Fields", :tiplocs =>'LONFLDS'},
"WPE" => {:lon => -0.055931,:lat => 51.504386,:name=>"Wapping", :tiplocs =>'WAPPING'},
"KGX" => {:lon => -0.122926,:lat => 51.530882,:name=>"London Kings Cross", :tiplocs =>'KNGX'},
"DLK" => {:lon => -0.075701,:lat => 51.548147,:name=>"Dalston Kingsland", :tiplocs =>'DALSKLD'},
"WAT" => {:lon => -0.113109,:lat => 51.503297,:name=>"London Waterloo", :tiplocs =>'WATRLMN'}
      }

      crs_tiplocs.each do |crs, station_info|
      # get lat, lon, name
         puts 'getting stats for crs '+crs+' tiplocs '+station_info[:tiplocs]
         performance_hash = Performance.get_station_performance(station_info[:tiplocs], 'departures')
         p performance_hash
         avg_secs_late = performance_hash[:avg_secs_late]
         sample_size = performance_hash[:n_live_deps]
         station_hash = {:crs => crs, :lon => station_info[:lon], :lat => station_info[:lat], :name => station_info[:name], :avg_secs_late => avg_secs_late, :sample_size => sample_size}
         performance_array.push(station_hash)
      end

=begin
      # array of stations we wish to get performance stats about
      crs_tiplocs = {"LST" => 'LIVST',"OLD" => 'OLDST',"MOG" => 'MRGT',"SDC" => 'SHRDHST',"HOX" => 'HOXTON',"FST" => 'FENCHRS',"CST" => 'CANONST',"ZFD" => 'FRNDNLT',"BET" => 'BTHNLGR',"ZWL" => 'WCHAPEL',"CTK" => 'CTMSLNK',"BFR" => 'BLFR',"HGG" => 'HAGGERS',"LBG" => 'LNDNBDG,LNDNBD,LNDNBDE,LNDNBAL,LNDNB9,LNDNB10,LNDNB11,LNDNB12,LNDNB13,LNDNB14,LNDNB1,LNDNB16,LNDN490',"CBH" => 'CAMHTH',"SDE" => 'SHADWEL',"EXR" => 'ESSEXRD',"WAE" => 'WLOE',"DLJ" => 'DALS',"LOF" => 'LONFLDS',"WPE" => 'WAPPING',"KGX" => 'KNGX',"DLK" => 'DALSKLD',"WAT" => 'WATRLMN'}
      crs_tiplocs.each do |crs, tiploc_code_csv|
      # get lat, lon, name
         puts 'getting stats for crs '+crs+' tiplocs '+tiploc_code_csv
         performance_hash = Performance.get_station_performance(tiploc_code_csv, 'departures')
         p performance_hash
         avg_secs_late = performance_hash[:avg_secs_late]
         sample_size = performance_hash[:n_live_deps]

         station_hash = {:crs => crs, :avg_secs_late => avg_secs_late, :sample_size => sample_size}
         performance_array.push(station_hash)
      end
=end
      # transform to json, and respond
      output_json = performance_array.to_json
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
      
      tiplocs_final_array = tiplocs_orig_array

       if (order_by == 'planned_arrival_timestamp' or order_by == 'predicted_arrival_timestamp')
         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_arrival)
       else
         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_departure)
       end      

      # Only display passenger schedules in normal mode
      # TODO fix midnight wrapping bug 
      before_range = 1.hour
      after_range = 2.hour
      #before_range = 3.hour
      #after_range = 2.hour
      @range = Hash.new
      now = DateTime.now
      #now = DateTime.now - 7.month + 10.hour
      @range[:from] = now -before_range
      @range[:to] = now + after_range

      @schedule = @schedule.runs_between(@range[:from], @range[:to], false)

      timetables_array=[] 

      # get timetables
      @schedule.each do |schedule|

         # get the origin / destination - speed this up
      #   p schedule

         bs_uuid = schedule[:obj].basic_schedule_uuid

         origin_name = 'nil'
         destin_name = 'nil' 

         origin_name = schedule[:obj].basic_schedule.origin_name
         destin_name = schedule[:obj].basic_schedule.destin_name

#         train_uid = schedule[:obj].train_uid
         
         # TODO could cause problems if now is after midnight
         # TODO ensure that the date of the TS is set to tomorrow, for next_day events
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
         
         #puts "planned_arrival_ts: "+planned_arrival_ts.to_s
         #puts "planned_departure_ts: "+planned_departure_ts.to_s
         
         matching_station_update = nil
         # get matching movement updates, based on uuid, and tiploc
         live_movement_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).where( :msg_type => '0003' )

         cancelled = false

         if live_movement_msgs.size() ==1
            move_msg = JSON.parse(live_movement_msgs[0]['msg_body'])
            event_type = move_msg['event_type']
            variation_status = move_msg['variation_status']
            timetable_variation_mins = move_msg['timetable_variation'].to_i

            #
            if timetable_variation_mins!= nil
            
#            "event_type":"DEPARTURE","gbtt_timestamp":"1353420000000","original_loc_stanox":"","planned_timestamp":"1353420000000","timetable_variation":"10","original_loc_timestamp":"","current_train_id":"","delay_monitoring_point":"true","next_report_run_time":"2","reporting_stanox":"88401","actual_timestamp":"1353420600000","correction_ind":"false","event_source":"AUTOMATIC","train_file_address":null,"platform":" 6","division_code":"80","train_terminated":"false","train_id":"882H42MO20","offroute_ind":"false","variation_status":"LATE",
               
               diff_from_timetable_secs = 0         
               diff_from_timetable_secs = timetable_variation_mins*60  if move_msg['variation_status'] == 'LATE'
               predicted_departure_timestamp = planned_departure_ts+(diff_from_timetable_secs) unless planned_departure_ts.nil?
               predicted_arrival_timestamp = planned_arrival_ts+(diff_from_timetable_secs) unless planned_arrival_ts.nil?
               
            end
         #else
         #   puts 'catch exceptions where there is no match'
         else
#HARRY MOVED THIS DOWN HERE
            # get matching cancel updates, based on uuid, and tiploc
            live_cancellation_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).where( :msg_type => '0002' )      
        #NOPE NOT WORKING                cancelled = true if live_cancellation_msgs.size() ==1
         end
          
         # check the include conditions: is planned/predicted arrival/departure in past/future
         # values can be t/f/nil
         # TODO SUSPECT THIS IS CAUSE OF MIDNIGHT WRAPPING BUG. SUSPECT THE DATES ON planned_arrival_ts etc are set to today, and so 23:20 appears to be gt 00:12
         planned_arrival_future = (Time.now < planned_arrival_ts) unless planned_arrival_ts.nil?
         predicted_arrival_future = (Time.now < predicted_arrival_timestamp) unless predicted_arrival_timestamp.nil?
         planned_departure_future = (Time.now < planned_departure_ts) unless planned_departure_ts.nil?
         predicted_departure_future = (Time.now < predicted_departure_timestamp) unless predicted_departure_timestamp.nil?

         # whether to include this departure (default=false)
         include_dep = false
         # hierarchy of checks of whether or not to include, set by first of 
         #   predicted departure, predicted arrival, planned departure, planned arrival
         # that is not null
         if predicted_departure_future != nil
            include_dep = predicted_departure_future
         elsif predicted_arrival_future != nil
            include_dep = predicted_arrival_future
         elsif planned_departure_future != nil
            include_dep = planned_departure_future
         elsif planned_arrival_future != nil
            include_dep = planned_arrival_future
         else 
            include_dep = false
         end
         
         
         # for departures planned arrival is in future   AND/OR predicted 
         # 1. planned arrival is in future   AND/OR predicted 
         #include_dep = true
         if include_dep
            timetable_hash = {}
            timetable_hash['tiploc_code'] = schedule[:obj].tiploc_code
            timetable_hash['station_name'] = schedule[:obj].tiploc.tps_description
            timetable_hash['platform'] = schedule[:obj].platform
            timetable_hash['origin_name'] = origin_name
            timetable_hash['destination_name'] = destin_name         

            timetable_hash['diff_from_timetable_secs'] = 0
            timetable_hash['diff_from_timetable_secs'] = diff_from_timetable_secs unless diff_from_timetable_secs.nil?
            timetable_hash['diff_from_timetable_secs'] = nil if cancelled == true

            timetable_hash['planned_arrival_timestamp'] = planned_arrival_ts
            timetable_hash['predicted_arrival_timestamp'] = planned_arrival_ts
            timetable_hash['predicted_arrival_timestamp'] = predicted_arrival_timestamp unless predicted_arrival_timestamp.nil?         
            timetable_hash['predicted_arrival_timestamp'] = nil if cancelled == true

            timetable_hash['planned_departure_timestamp'] = planned_departure_ts         
            timetable_hash['predicted_departure_timestamp'] = planned_departure_ts
            timetable_hash['predicted_departure_timestamp'] = predicted_departure_timestamp unless predicted_departure_timestamp.nil?         
            timetable_hash['predicted_departure_timestamp'] = nil if cancelled == true

            timetable_hash['event_type'] = nil
            timetable_hash['event_type'] =event_type unless event_type.nil?
            timetable_hash['variation_status'] = 'NO REPORT'         
            timetable_hash['variation_status'] = 'CANCELLED' if cancelled == true
            timetable_hash['variation_status'] = variation_status unless variation_status.nil?
            timetable_hash['operator_ref'] = nil
            timetable_hash['service_name'] = nil
            timetable_hash['service_name'] = schedule[:obj].basic_schedule.service_code unless schedule[:obj].basic_schedule.nil?
            timetable_hash['operator_ref'] = schedule[:obj].basic_schedule.atoc_code unless schedule[:obj].basic_schedule.nil?
            timetables_array << timetable_hash        
         end
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
