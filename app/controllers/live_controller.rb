###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Jul 2012
# A live departures controller
###########################################################


require 'json'
require "performance" # works

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

   # returns performance stats for specified array of stations
   def station_performance_json

      performance_array = []

      # input crs para is an array of the form 
      #MAS,NCL,WEH,DOT,MCE,HEW,BLO,APN,BNR,CRM,WYM,EBL,CLS,SEB,PRU,STZ,SUN,MPT,DHM,PEG
      crs_array = params[:crs].upcase.split(',')
      crs_array.each do |crs|
         # TODO note limitation - we are mapping one crs to one tiploc. Not making reference to Peter Hicks' CRS <-> tiploc lookup table
         tiplocs = Tiploc.find_by_crs_code(crs)
         station_hash = {:crs => crs}
         unless tiplocs.nil?
            tiploc_codes = tiplocs.tiploc_code
	        performance_hash = Performance.get_station_performance(tiploc_codes, 'departures')
	        station_hash = { :crs => crs, :tiplocs => tiploc_codes, :avg_secs_late => performance_hash[:avg_secs_late], :sample_size => performance_hash[:n_live_deps]}
#	        station_hash = { crs => { :tiplocs => tiploc_codes, :avg_secs_late => performance_hash[:avg_secs_late], :sample_size => performance_hash[:n_live_deps]} }
         end
         performance_array.push(station_hash)
      end
      # transform to json, and respond
      output_json = hash_to_json(performance_array, params['callback'] )
      send_data output_json,
            :type => "text/plain",
            :disposition => 'inline' 

   end
   
=begin
   # returns performance stats for specified array of stations
   def station_performance_json

      performance_array = []

#      crs_array = ["MAS", "NCL", "WEH", "DOT" ,"MCE" ,"HEW" ,"BLO" ,"APN" ,"BNR" ,"CRM" ,"WYM" ,"EBL" ,"CLS" ,"SEB" ,"PRU" ,"STZ" ,"SUN" ,"MPT" ,"DHM" ,"PEG" ]
#      tiplocs_array = ['MANORS','NWCSTLE','DNSN','GTSHDMC','HEWORTH','BLAYDON','AIRP','BRWHINS','CRMLNGT','WYLAM','EBOLDON','CLST','SEABURN','PRUDHOE','SNDRMNK','SNDRLND','MRPTHRP','DRHM','PEGSWD']

      # input crs para is an array of the form 
      #MAS,NCL,WEH,DOT,MCE,HEW,BLO,APN,BNR,CRM,WYM,EBL,CLS,SEB,PRU,STZ,SUN,MPT,DHM,PEG
      crs_array = params[:crs].upcase.split(',')
      crs_array.each do |crs|
         # TODO note limitation - we are mapping one crs to one tiploc. Not making reference to Peter Hicks' CRS <-> tiploc lookup table
         tiplocs = Tiploc.find_by_crs_code(crs)
         station_hash = {:crs => crs}
         unless tiplocs.nil?
            tiploc_codes = tiplocs.tiploc_code
	        performance_hash = Performance.get_station_performance(tiploc_codes, 'departures')
	        station_hash = {:crs => crs, :tiplocs => tiploc_codes, :avg_secs_late => performance_hash[:avg_secs_late], :sample_size => performance_hash[:n_live_deps]}
         end
         performance_array.push(station_hash)
      end
      # transform to json, and respond
      output_json = hash_to_json(performance_array, params['callback'] )
      send_data output_json,
            :type => "text/plain",
            :disposition => 'inline' 

   end
=end
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
#         p performance_hash
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
#         p performance_hash
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

=begin
  # a quality test for live station updates. how many are tracked?
  def stations_updates_quality_json

    tiplocs_string = params[:tiploc].upcase

    # formulate a hash response
    @response = {}
    @response['tiploc_code'] = tiplocs_string
    @response['departures'] = []

    # for each departure, compare time departed origin with now.
    now = Time.now

    # if the train is supposed to have departured, but we have no activation msg, 
    #
    # perform checks to assess whether we have any activation/movement msgs for this service, and if it should be moving at this time
    activation_msg_received=false
    movement_msg_received=false
    train_should_be_moving=false


    # transform to json, and respond
    output_json = @response.to_json
    send_data output_json, :type => "text/plain", :disposition => 'inline'      

  end
=end



   # Return all known live updates for a station, in json format
   def stations_updates_json

      # formulate a hash response
      @response = get_stations_updates_hash

      # transform to json, and respond
      output_json = @response.to_json
      send_data output_json, :type => "text/plain", :disposition => 'inline'
   end
   
   
    # Return all known live updates for a station, as a hash
    def get_stations_updates_hash

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

        # a useful snippet for altering 'now' for debug, e.g. for the midnight wrapping bug
        debug=false
        if debug
            now = DateTime.now.midnight
        end
        before_range = 1.hour
        after_range = 2.hour
        @range = Hash.new
        @range[:from] = now -before_range
        @range[:to] = now + after_range
        @schedule = @schedule.runs_between(@range[:from], @range[:to], false)

        # get timetables from schedules
        timetables_array=[] 
        @schedule.each do |schedule|

            
            
            #puts '================='
            #p schedule
            # get the id, and origin/destin
            bs_uuid = schedule[:obj].basic_schedule_uuid
            #origin_name = 'nil'
            #destin_name = 'nil' 
            #origin_departure_public = 'nil'
            origin_name = schedule[:obj].basic_schedule.origin_name
            origin_name = schedule[:obj].basic_schedule.origin_tiploc if origin_name.nil?
            destin_name = schedule[:obj].basic_schedule.destin_name
            destin_name = schedule[:obj].basic_schedule.destin_tiploc if destin_name.nil?
            origin_departure_public =  schedule[:obj].basic_schedule.origin_public_departure
            train_uid = schedule[:obj].basic_schedule.train_uid

            # get the mode, based on category: see http://www.atoc.org/clientfiles/File/RSPS5004%20v27.pdf page iv 
            # note that vehicle_mode_train_value must be synched with TAPI config/initializers/transportapi.rb file
            mode = vehicle_mode_train_value
            if schedule[:obj].basic_schedule.category[0] == 'B'
                mode = vehicle_mode_bus_value
            end

            # get the timestamp for arrival/departure time
            planned_arrival_ts = date_and_time_to_timestamp(schedule[:runs_on], schedule[:obj].public_arrival, schedule[:obj].next_day_arrival)
            planned_departure_ts = date_and_time_to_timestamp(schedule[:runs_on], schedule[:obj].public_departure, schedule[:obj].next_day_departure)

            # should this train now be moving, according to timetable?
            train_scheduled_to_have_left_origin = false
            #puts "schedule[:obj].basic_schedule = "+schedule[:obj].basic_schedule.to_s
            #puts "schedule[:obj].basic_schedule.origin_public_departure = "+schedule[:obj].basic_schedule.origin_public_departure.to_s
            #puts "schedule[:obj].basic_schedule.uuid = "+schedule[:obj].basic_schedule.uuid.to_s
            origin_departure_ts = date_and_time_to_timestamp(schedule[:runs_on], schedule[:obj].basic_schedule.origin_public_departure, false)
            #puts "origin_departure_ts = "+origin_departure_ts.to_s
            # TODO allow for 1 minute grace
            unless origin_departure_ts.nil?
                
             #       puts 'train scheduled to be moving'
                    train_scheduled_to_have_left_origin = true if origin_departure_ts < (now - 1.minute)
             #   else 
             #       puts 'train not scheduled to be moving'
             #   end
             else
                 puts 'DEPARTURE TIME FROM ORIGIN IS NULL - '
             end
 
				 puts 'origin_name = '+origin_name.to_s
				 puts 'destin_name = '+destin_name.to_s
				 puts "train_scheduled_to_have_left_origin = "+train_scheduled_to_have_left_origin.to_s
				 puts "origin_departure_ts = "+origin_departure_ts.to_s
				 puts "now = "+now.to_s
				 puts "planned_arrival_ts = "+planned_arrival_ts.to_s unless planned_arrival_ts.nil?
				 puts "planned_departure_ts = "+planned_departure_ts.to_s unless planned_departure_ts.nil?
				# is this an origin station
				#puts 'schedule[:obj].basic_schedule.origin_public_departure = ' +schedule[:obj].basic_schedule.origin_public_departure.to_s
                
#            augmented_variation_status = "null status"
            augmented_variation_status = "NO REPORT"
				# record if this is an origin station
				origin_station = false
				if schedule[:obj].basic_schedule.origin_public_departure ==  schedule[:obj].public_departure
					puts "this is an origin station"
					origin_station = true
				end

				puts 'bs_uuid '+bs_uuid

				#puts 'setting augmented_variation_status to default '+augmented_variation_status
            live_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).order('updated_at DESC')
            n_live_msgs = live_msgs.size()
				puts 'n_live_msgs = '+n_live_msgs.to_s
            cancelled = false
            # case where we have a live msg - will dictate our status report
            if n_live_msgs >=1
                # get the latest msg
                live_msg_body = JSON.parse(live_msgs[0]['msg_body'])
                live_msg = live_msgs[0]
                msg_type = live_msg['msg_type']

                #puts "live_msg_body = "+live_msg_body.to_s
                #puts "msg_type = "+msg_type.to_s
            
                # the ordering is important, since these are if/elses
                # 
                if msg_type == '0003' # movement
						 puts 'we got a 0003 msg'
                    #puts 'movement'
						  #p live_msg_body
                    event_type = live_msg_body['event_type']
                    augmented_variation_status = live_msg_body['variation_status']
		  				  #puts 'setting augmented_variation_status to live_msg[variation_status] '+augmented_variation_status
						  
                    timetable_variation_mins = live_msg_body['timetable_variation'].to_i
                    
                    # is this an arrival message, related to this station? Get this from loc_stanox...
                    # if so, we can use the live platform information			
                    # get variation from timetable
                    if timetable_variation_mins!= nil
	  						 puts 'timetable_variation_mins = '+timetable_variation_mins.to_s
                        diff_from_timetable_secs = 0         
                        # note we only adjust for late trains. early trains will just be on time!
                        diff_from_timetable_secs = timetable_variation_mins*60  if live_msg_body['variation_status'] == 'LATE'
                        predicted_departure_timestamp = planned_departure_ts+(diff_from_timetable_secs.seconds) unless planned_departure_ts.nil?
                        predicted_arrival_timestamp = planned_arrival_ts+(diff_from_timetable_secs.seconds) unless planned_arrival_ts.nil?               
                        # be more sophisticated in definition of 'late', 'early', 'on time'
                        # if more than 2 mins late, report late. Otherwise, report 'on time'
                    end                    
                elsif msg_type == '0005' # reinstatement TODO handle this case
                    puts 'reinstatement'
                    augmented_variation_status = 'REINSTATEMENT'
		  				  puts 'setting augmented_variation_status to REINSTATEMENT '+augmented_variation_status
						  
                elsif msg_type == '0002' # cancellation
                    puts 'cancellation'
                    cancelled = true
                    augmented_variation_status = 'CANCELLED'
		  				  puts 'setting augmented_variation_status to CANCELLED '+augmented_variation_status						  
#                elsif msg_type == '0004' # unidentified - NOT USED IN PROD
#                    puts 'unidentified'
#                    augmented_variation_status = 'UNIDENTIFIED'
                elsif msg_type == '0006' # change_of_origin TODO handle this case
                    puts 'change_of_origin'
                    augmented_variation_status = 'CHANGE OF ORIGIN'
		  				  puts 'setting augmented_variation_status to CHANGE OF ORIGIN '+augmented_variation_status
						  
                elsif msg_type == '0007' # change_of_identity TODO handle this case
                    puts 'change_of_identity'
                    augmented_variation_status = 'CHANGE OF IDENTITY'
		  				  puts 'setting augmented_variation_status to HANGE OF IDENTITY '+augmented_variation_status
						  
#                elsif msg_type == '0008' # change_of_location - NOT USED IN PROD
#                    puts 'change_of_location'
#                    augmented_variation_status = 'UNIDENTIFIED'
	             elsif  msg_type == '0001' # activation
		             puts 'activation'
		             if train_scheduled_to_have_left_origin
		                 puts 'train is supposed to be moving'
		                 augmented_variation_status = 'LATE'
			  				  puts 'setting augmented_variation_status to LATE '+augmented_variation_status							  
		             else
		                 #puts 'train not moving yet'
		                 augmented_variation_status = 'ON TIME'    
							  # TODO but if its an origin station, say 'starts here'
							  augmented_variation_status = 'STARTS HERE'    if origin_station == true
			  				  puts 'setting augmented_variation_status to ON TIME '+augmented_variation_status							                  
		             end

	             #elsif msg_type == '0008' # change_of_location - NOT USED IN PROD
	             #    puts 'change_of_location'					 
                else
                    puts 'unknown or unused msg type '+ msg_type.to_s
                end
            # if no live msgs...
            else # n_live_msgs ==0- by definition, no activation msg has been received
#                puts "no live msgs"

=begin
                activation_msg_received = false
                # has train been activated?
                activation_msgs = TrackedTrain.where( :basic_schedule_uuid => bs_uuid )
                if activation_msgs.size() ==1
                    activation_msg_received = true
                elsif 	activation_msgs.size() > 1
                    puts 'multiple activation messages for a single scheduled departure'
                    p schedule
                    puts 'problematic'
                else 
                    puts 'no activation msgs for bs_uuid '+bs_uuid.to_s
                end
=end                
                # if train is supposed to have left origin....
                if train_scheduled_to_have_left_origin
=begin
                    if activation_msg_received # if we've had an activation, assume its late
                        augmented_variation_status = 'LATE'
	 		  				   #puts 'setting augmented_variation_status to LATE '+augmented_variation_status								
                        #puts "train should be moving - list as no report - we should at least have received an activation by now"
                    else # if no activatin received, this is a no report
=end
                        augmented_variation_status = 'NO REPORT'
 	 		  				   #puts 'setting augmented_variation_status to NO REPORT '+augmented_variation_status								
                        #puts "train should be moving - list as no report - we should at least have received an activation by now"
#                    end
                else # if its not supposed to have left origin, assume its on time
                    augmented_variation_status = 'ON TIME'   
						  # TODO but if its an origin station, say 'starts here'
						  augmented_variation_status = 'STARTS HERE'  if origin_station == true						  
 		  				  #puts 'setting augmented_variation_status to ON TIME '+augmented_variation_status
                    #puts "train not yet moving - assume that train will on time?"
                end
            #else
            #    puts ""+n_live_msgs.to_s+" live msgs ? This is problematic"
            end
            puts 'final augmented_variation_status ='+augmented_variation_status.to_s
            puts '--------------------------------------------------------'

=begin            
            # have we received an activation msg for this scheduled service 
            activation_msg_received = false
            # have we received a movement msg for this scheduled service 
            movement_msg_received = false
            

            activation_msgs = TrackedTrain.where( :basic_schedule_uuid => bs_uuid )
            if activation_msgs.size() ==1
                activation_msg_received = true
            elsif 	activation_msgs.size() > 1
                puts 'multiple activation messages for a single scheduled departure'
                p schedule
                puts 'problematic'
            else 
                puts 'no activation msgs for bs_uuid '+bs_uuid.to_s
            end
            # get matching movement updates, based on uuid, and tiploc
            live_movement_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).where( :msg_type => '0003' )

            # flags if train is cancelled
            cancelled = false



            #origin_departure_ts = origin_departure_ts.change({:year => origin_departure_day.year,:month => origin_departure_day.month,:day => origin_departure_day.day,:hour => origin_public_departure[0,2].to_i, :min => origin_public_departure[2,2].to_i,:sec => 0})
            #puts 'origin_departure_ts = '
            #p origin_departure_ts


            # use live platform information, if available
            #live_platform = nil 

            if live_movement_msgs.size() ==1
                movement_msg_received = true
                move_msg = JSON.parse(live_movement_msgs[0]['msg_body'])
                event_type = move_msg['event_type']
                variation_status = move_msg['variation_status']
                timetable_variation_mins = move_msg['timetable_variation'].to_i

                # is this an arrival message, related to this station? Get this from loc_stanox...
                # if so, we can use the live platform information			
                # get variation from timetable
                if timetable_variation_mins!= nil
                    diff_from_timetable_secs = 0         
                    # note we only adjust for late trains. early trains will just be on time!
                    diff_from_timetable_secs = timetable_variation_mins*60  if move_msg['variation_status'] == 'LATE'
                    predicted_departure_timestamp = planned_departure_ts+(diff_from_timetable_secs.seconds) unless planned_departure_ts.nil?
                    predicted_arrival_timestamp = planned_arrival_ts+(diff_from_timetable_secs.seconds) unless planned_arrival_ts.nil?               
                end
            else
                # get matching cancel updates, based on uuid, and tiploc
                live_cancellation_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).where( :msg_type => '0002' )      
                if live_cancellation_msgs.size() ==1
                    cancelled = true
                end
            end
=end
            
            
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

            # Live platform info is only available as a trains pulls into station (the latest arrival msg)  - so we are forced to use timetabled platform
            timetabled_platform = schedule[:obj].platform
            platform_to_report = timetabled_platform

            # for arrs/deps that are in the future, construct and add a hash
            if include_dep

                #augmented_variation_status = 'NO REPORT'         
                #augmented_variation_status = 'CANCELLED' if cancelled == true

                #augmented_variation_status = variation_status unless variation_status.nil?

                # have we received an activation msg for this scheduled service 
                #puts "activation_msg_received = "+activation_msg_received.to_s
                #puts "movement_msg_received = "+movement_msg_received.to_s
                #puts "train_scheduled_to_have_left_origin = "+train_scheduled_to_have_left_origin.to_s


                #if variation_status.nil? 
                #    puts 'augmented_variation_status is nil'
                #else
                #    puts 'augmented_variation_status = '+augmented_variation_status.to_s
                #end

                timetable_hash = {}

                timetable_hash[vehicle_mode_key_name] = mode
                timetable_hash['tiploc_code'] = schedule[:obj].tiploc_code
                timetable_hash['station_name'] = schedule[:obj].tiploc.tps_description

                timetable_hash['platform'] = platform_to_report

                timetable_hash['origin_name'] = origin_name
                timetable_hash['origin_departure'] = origin_departure_public
                timetable_hash['destination_name'] = destin_name         
                timetable_hash['train_uid'] = train_uid         
                #timetable_hash['activation_msg_received'] = activation_msg_received         
                #timetable_hash['movement_msg_received'] = movement_msg_received         
                timetable_hash['train_scheduled_to_have_left_origin'] = train_scheduled_to_have_left_origin         

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
					 #augmented_variation_status = 'NO REPORT'
                timetable_hash['variation_status'] = augmented_variation_status        
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
        return @response

    end

=begin

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

	  # a useful snippet for altering 'now' for debug, e.g. for the midnight wrapping bug
	  debug  =false
	  if debug
      	now = DateTime.now.midnight
      	
#      	now = now - 61.minutes # ok
#      	now = now - 59.minutes # ok
#      	now = now - 10.minutes # ok
#      	now = now - 1.minutes # ok
#      	now = now + 1.minutes # ok
#      	now = now + 50.minutes #  ok
#      	now = now + 61.minutes # bug!
#      	now = now + 91.minutes # ok

#      	now = now + 31.days
#      	now = now + 10.hour
#      	now = now + 45.minute
#      	puts 'setting the date to future'
  	  end
      before_range = 1.hour
      after_range = 2.hour
      @range = Hash.new
      @range[:from] = now -before_range
      @range[:to] = now + after_range
      @schedule = @schedule.runs_between(@range[:from], @range[:to], false)

      # get timetables from schedules
      timetables_array=[] 
      @schedule.each do |schedule|
      #p schedule
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
			if schedule[:obj].next_day_arrival == true # add an extra day, if its a next day arrival
				planned_ds_arrival_day = planned_ds_arrival_day+1.day 
			end		
            planned_arrival_ts = now
            planned_arrival_ts = planned_arrival_ts.change({:year => planned_ds_arrival_day.year,:month => planned_ds_arrival_day.month,:day => planned_ds_arrival_day.day,:hour => planned_arrival_hhmm[0,2].to_i, :min => planned_arrival_hhmm[2,2].to_i,:sec => 0})
         end
         unless schedule[:obj].public_departure.nil?
            planned_departure_hhmm = schedule[:obj].public_departure
            planned_ds_departure_day = schedule[:runs_on]
            if schedule[:obj].next_day_departure == true         # add an extra day, if its a next day arrival
	            planned_ds_departure_day = planned_ds_departure_day+1.day  
	        end
	        # a bug is still observed here for when    
	        # now = now + 61.minutes # bug!
# for the URL http://placraa3.miniserver.com:3000/live/station/CLPHMJC
# http://4.placr.co.uk/v3/uk/train/station/CLJ/live
# 00:07	London Victoria	no report	14 is observed
# {:a=>Wed, 11 Jun 2014 00:00:00 +0100, :p=>nil, :d=>Sun, 10 Aug 2014 00:00:00 +0100, :runs_on=>Fri, 17 May 2013 00:00:00 +0100, :obj=>#<Location id: 8198022, basic_schedule_uuid: "db049eb0-9e0e-0130-093d-10b11c15c7ff", location_type: "LI", tiploc_code: "CLPHMJC", tiploc_instance: nil, arrival: "0006H", public_arrival: "0007", pass: nil, departure: "0007H", public_departure: "0007", platform: "14", line: "SL", path: nil, engineering_allowance: nil, pathing_allowance: nil, performance_allowance: nil, created_at: "2013-05-13 15:22:42", updated_at: "2013-05-13 15:22:42", seq: 160, activity_ae: false, activity_bl: false, activity_minusd: false, activity_hh: false, activity_kc: false, activity_ke: false, activity_kf: false, activity_ks: false, activity_op: false, activity_or: false, activity_pr: false, activity_rm: false, activity_rr: false, activity_minust: false, activity_tb: false, activity_tf: false, activity_ts: false, activity_tw: false, activity_minusu: false, activity_a: false, activity_c: false, activity_d: false, activity_e: false, activity_g: false, activity_h: false, activity_k: false, activity_l: false, activity_n: false, activity_r: false, activity_s: false, activity_t: true, activity_u: false, activity_w: false, activity_x: false, next_day_arrival: false, next_day_departure: true, arrival_secs: 390, departure_secs: 450, pass_secs: nil, public_arrival_secs: 420, public_departure_secs: 420>}
            planned_departure_ts = now
            planned_departure_ts = planned_departure_ts.change({:year => planned_ds_departure_day.year,:month => planned_ds_departure_day.month,:day => planned_ds_departure_day.day,:hour => planned_departure_hhmm[0,2].to_i, :min => planned_departure_hhmm[2,2].to_i,:sec => 0})
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
#               predicted_departure_timestamp = planned_departure_ts+(diff_from_timetable_secs) unless planned_departure_ts.nil?
#               predicted_arrival_timestamp = planned_arrival_ts+(diff_from_timetable_secs) unless planned_arrival_ts.nil?               
               predicted_departure_timestamp = planned_departure_ts+(diff_from_timetable_secs.seconds) unless planned_departure_ts.nil?
               predicted_arrival_timestamp = planned_arrival_ts+(diff_from_timetable_secs.seconds) unless planned_arrival_ts.nil?               
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
=end


   	# Returns a full timestamp with date, based upon a live hhcmm time.   	
   	# Based on now.hour - departure.hour
   	# A large positive difference (e.g. 23-0=23) suggests departure is tomorrow
   	# A large negative difference (e.g. 0-23=-23) suggests departure is yesterday 
   	# Small differences (e.g. 23-23=0, 22-23=-1, 23-22=1) suggests departure is today 
	def departure_timestamp_from_live_hhcmm(hhcmm)
		puts 'hhcmm = '+hhcmm.to_s
		# get first and last timestamps in tapi_deps
		now = Time.now
		dep_timestamp = now.change(:hour => hhcmm[0..1], :min => hhcmm[3..4])
		hour_diff = (now.hour - dep_timestamp.hour)
		if  hour_diff > 12 
			dep_timestamp = dep_timestamp+1.day
		elsif hour_diff < -12 
			dep_timestamp = dep_timestamp-1.day
		end
		return dep_timestamp
	end
	
    
    
    # converts a departure date (as a timestamp), a time as (hhmm), and whether a scheduled time is next day relative to service origin departure (as t/f)
    # into a timestamp for a departure
    # a bug is still observed here for when    
    # now = now + 61.minutes # bug!
    # for the URL http://placraa3.miniserver.com:3000/live/station/CLPHMJC
    # http://4.placr.co.uk/v3/uk/train/station/CLJ/live
    # 00:07	London Victoria	no report	14 is observed
    # {:a=>Wed, 11 Jun 2014 00:00:00 +0100, :p=>nil, :d=>Sun, 10 Aug 2014 00:00:00 +0100, :runs_on=>Fri, 17 May 2013 00:00:00 +0100, :obj=>#<Location id: 8198022, basic_schedule_uuid: "db049eb0-9e0e-0130-093d-10b11c15c7ff", location_type: "LI", tiploc_code: "CLPHMJC", tiploc_instance: nil, arrival: "0006H", public_arrival: "0007", pass: nil, departure: "0007H", public_departure: "0007", platform: "14", line: "SL", path: nil, engineering_allowance: nil, pathing_allowance: nil, performance_allowance: nil, created_at: "2013-05-13 15:22:42", updated_at: "2013-05-13 15:22:42", seq: 160, activity_ae: false, activity_bl: false, activity_minusd: false, activity_hh: false, activity_kc: false, activity_ke: false, activity_kf: false, activity_ks: false, activity_op: false, activity_or: false, activity_pr: false, activity_rm: false, activity_rr: false, activity_minust: false, activity_tb: false, activity_tf: false, activity_ts: false, activity_tw: false, activity_minusu: false, activity_a: false, activity_c: false, activity_d: false, activity_e: false, activity_g: false, activity_h: false, activity_k: false, activity_l: false, activity_n: false, activity_r: false, activity_s: false, activity_t: true, activity_u: false, activity_w: false, activity_x: false, next_day_arrival: false, next_day_departure: true, arrival_secs: 390, departure_secs: 450, pass_secs: nil, public_arrival_secs: 420, public_departure_secs: 420>}

    def date_and_time_to_timestamp(date, hhmm, next_day)
        if hhmm.nil?
            return nil
        else
            if next_day == true # add an extra day, if its a next day arrival
                date = date+1.day 
            end		
            planned_ts = Time.now
            planned_ts = planned_ts.change({:year => date.year,:month => date.month,:day => date.day,:hour => hhmm[0,2].to_i, :min => hhmm[2,2].to_i,:sec => 0})
            return planned_ts
        end        
    end
    
    
end
