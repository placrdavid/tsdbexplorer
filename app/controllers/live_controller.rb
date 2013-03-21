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
   def newcastle_performance_json

      performance_array = []


      # TODO get nearest request from transport API
      #http://transportapi.com/v3/uk/train/stations/near.json?lon=-1.61778&lat=54.9782520
      # endpoint should also return tiplocss
      crs_tiplocs = {
"MAS" => {:name => "Manors", :lon => -1.604741, :lat => 54.972763,:distance => 1800, :tiplocs =>'MANORS'},
"NCL" => {:name => "Newcastle", :lon => -1.61728, :lat => 54.9684,:distance => 1912, :tiplocs =>'NWCSTLE'},
"DOT" => {:name => "Dunston", :lon => -1.642044, :lat => 54.950054,:distance => 6099, :tiplocs =>'DNSN'},
"MCE" => {:name => "Metro Centre", :lon => -1.665626, :lat => 54.958748,:distance => 6533, :tiplocs =>'GTSHDMC'},
"HEW" => {:name => "Heworth", :lon => -1.555766, :lat => 54.951567,:distance => 8627, :tiplocs =>'HEWORTH'},
"BLO" => {:name => "Blaydon", :lon => -1.712581, :lat => 54.965787,:distance => 10827, :tiplocs =>'BLAYDON'},
"APN" => {:name => "Airport (Newcastle)", :blon => -1.711047, :lat => 55.035948,:distance => 15272, :tiplocs =>'AIRP'},
"BNR" => {:name => "Brockley Whins", :lon => -1.461353, :lat => 54.959543,:distance => 17787, :tiplocs =>'BRWHINS'},
"CRM" => {:name => "Cramlington", :lon => -1.598595, :lat => 55.087766,:distance => 21379, :tiplocs =>'CRMLNGT'},
"WYM" => {:name => "Wylam", :lon => -1.814062, :lat => 54.97497,:distance => 21859, :tiplocs =>'WYLAM'},
"EBL" => {:name => "East Boldon", :lon => -1.420314, :lat => 54.946414,:distance => 22832, :tiplocs =>'EBOLDON'},
"CLS" => {:name => "Chester Le Street", :lon => -1.578015, :lat => 54.854593,:distance => 24356, :tiplocs =>'CLST'},
"SEB" => {:name => "Seaburn", :lon => -1.386693, :lat => 54.929534,:distance => 27403, :tiplocs =>'SEABURN'},
"PRU" => {:name => "Prudhoe", :lon => -1.864866, :lat => 54.965827,:distance => 27611, :tiplocs =>'PRUDHOE'},
"STZ" => {:name => "St Peters", :lon => -1.383802, :lat => 54.911439,:distance => 29088, :tiplocs =>'SNDRMNK'},
"SUN" => {:name => "Sunderland", :lon => -1.382304, :lat => 54.905338,:distance => 29779, :tiplocs =>'SNDRLND'},
"MPT" => {:name => "Morpeth", :lon => -1.683075, :lat => 55.162375,:distance => 36528, :tiplocs =>'MRPTHRP'},
"DHM" => {:name => "Durham", :lon => -1.581752, :lat => 54.779389,:distance => 38688, :tiplocs =>'DRHM'},
"PEG" => {:name => "Pegswood", :lon => -1.644166, :lat => 55.178128,:distance => 38979, :tiplocs =>'PEGSWD'}
	}

      crs_tiplocs.each do |crs, station_info|
      # get lat, lon, name
         #puts 'getting stats for crs '+crs+' tiplocs '+station_info[:tiplocs]
         performance_hash = Performance.get_station_performance(station_info[:tiplocs], 'departures')
         p performance_hash
         avg_secs_late = performance_hash[:avg_secs_late]
         sample_size = performance_hash[:n_live_deps]
         station_hash = {:crs => crs, :lon => station_info[:lon], :lat => station_info[:lat], :name => station_info[:name], :avg_secs_late => avg_secs_late, :sample_size => sample_size}
         performance_array.push(station_hash)
      end

      # transform to json, and respond
      #output_json = performance_array.to_json
      #send_data output_json, :type => "text/plain", :disposition => 'inline'
      
      output_json = hash_to_json(performance_array, params['callback'] )
      send_data output_json,
            :type => "text/plain",
            :disposition => 'inline' 


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
         #puts 'getting stats for crs '+crs+' tiplocs '+station_info[:tiplocs]
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
      #output_json = performance_array.to_json
      #send_data output_json, :type => "text/plain", :disposition => 'inline'
      
      #output_json = performance_array.to_json
      #send_data output_json, :type => "text/plain", :disposition => 'inline'
      
      output_json = hash_to_json(performance_array, params['callback'] )
      send_data output_json,
            :type => "text/plain",
            :disposition => 'inline' 

   end

   # Return all known live updates for a station, in json format
   def stations_updates_json

		# vehicle mode key and value names
		# These MUST be synchronised with the Transport API config/initializers/transportapi.rb file
		# VEHICLE_MODE_KEY_NAME, VEHICLE_MODE_BUS_VALUE, VEHICLE_MODE_TRAIN_VALUE
		vehicle_mode_key_name = 'mode'
		vehicle_mode_bus_value = 'bus'
		vehicle_mode_train_value = 'train'


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

	  # get our locations, ordered as requested
      if (order_by == 'planned_arrival_timestamp' or order_by == 'predicted_arrival_timestamp')
         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_arrival)
      else
         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_departure)
      end      

      # get the timerange, based on now
      now = DateTime.now
=begin      
	  # a useful snippet for altering 'now' for debug, e.g. for the midnight wrapping bug
	  debug  =false
	  if debug
      	now = DateTime.now.midnight
      	now = now + 10.minutes
  	  end
=end
      before_range = 1.hour
      after_range = 2.hour
      @range = Hash.new
      @range[:from] = now -before_range
      @range[:to] = now + after_range
      @schedule = @schedule.runs_between(@range[:from], @range[:to], false)


      # get timetables from schedules
      timetables_array=[] 
      @schedule.each do |schedule|

		# get the id, and origin/destin
         bs_uuid = schedule[:obj].basic_schedule_uuid
         origin_name = 'nil'
         destin_name = 'nil' 
         origin_name = schedule[:obj].basic_schedule.origin_name
         destin_name = schedule[:obj].basic_schedule.destin_name
         train_uid = schedule[:obj].basic_schedule.train_uid
         
         # get the mode, based on category: see http://www.atoc.org/clientfiles/File/RSPS5004%20v27.pdf page iv 
         # note that vehicle_mode_train_value must be synched with TAPI config/initializers/transportapi.rb file
         mode = vehicle_mode_train_value
         if schedule[:obj].basic_schedule.category[0] == 'B'
	         mode = vehicle_mode_bus_value
         end

		 # create a datetime from a date and a time, for arr and dep
         unless schedule[:obj].public_arrival.nil?
            planned_arrival_hhmm = schedule[:obj].public_arrival
            planned_ds_arrival_day = schedule[:runs_on]
            planned_arrival_ts = Time.utc(planned_ds_arrival_day.year,planned_ds_arrival_day.month,planned_ds_arrival_day.day,planned_arrival_hhmm[0,2].to_i,  planned_arrival_hhmm[2,2].to_i)               
         end
         unless schedule[:obj].public_departure.nil?
            planned_departure_hhmm = schedule[:obj].public_departure
            planned_ds_departure_day = schedule[:runs_on]
            planned_departure_ts = Time.utc(planned_ds_departure_day.year,planned_ds_departure_day.month,planned_ds_departure_day.day,planned_departure_hhmm[0,2].to_i,  planned_departure_hhmm[2,2].to_i)               
         end

         matching_station_update = nil

         # get matching movement updates, based on uuid, and tiploc
         live_movement_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).where( :msg_type => '0003' )

		 # flags if train is cancelled
         cancelled = false

         if live_movement_msgs.size() ==1
            move_msg = JSON.parse(live_movement_msgs[0]['msg_body'])
            event_type = move_msg['event_type']
            variation_status = move_msg['variation_status']
            timetable_variation_mins = move_msg['timetable_variation'].to_i

            # get variation from timetable
            if timetable_variation_mins!= nil
               diff_from_timetable_secs = 0         
               # note we only adjust for late trains. early trains will just be on time!
               diff_from_timetable_secs = timetable_variation_mins*60  if move_msg['variation_status'] == 'LATE'
               predicted_departure_timestamp = planned_departure_ts+(diff_from_timetable_secs) unless planned_departure_ts.nil?
               predicted_arrival_timestamp = planned_arrival_ts+(diff_from_timetable_secs) unless planned_arrival_ts.nil?               
            end
         else
            # get matching cancel updates, based on uuid, and tiploc
            live_cancellation_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).where( :msg_type => '0002' )      
            if live_cancellation_msgs.size() ==1
               cancelled = true
            end
         end
          
         # check the include conditions: is planned/predicted arrival/departure in past/future
         planned_arrival_future = (now <= planned_arrival_ts) unless planned_arrival_ts.nil?
         predicted_arrival_future = (now <= predicted_arrival_timestamp) unless predicted_arrival_timestamp.nil?
         planned_departure_future = (now <= planned_departure_ts) unless planned_departure_ts.nil?
         predicted_departure_future = (now <= predicted_departure_timestamp) unless predicted_departure_timestamp.nil?

         # whether to include this departure (default=false)
         include_dep = false
         # We only want to include future events
         # Hierarchy of checks of whether or not to include, set by first of 
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
         
         # for arrs/deps that are in the future, construct and add a hash
         if include_dep
            timetable_hash = {}

            timetable_hash[vehicle_mode_key_name] = mode
            timetable_hash['tiploc_code'] = schedule[:obj].tiploc_code
            timetable_hash['station_name'] = schedule[:obj].tiploc.tps_description
            timetable_hash['platform'] = schedule[:obj].platform
            timetable_hash['origin_name'] = origin_name
            timetable_hash['destination_name'] = destin_name         
            timetable_hash['train_uid'] = train_uid         

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
