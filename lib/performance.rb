###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Jan 2013
# Live performance stats
###########################################################

require 'json'

class Performance 
   
   def Performance.test
      puts 'test'
   end
   
   # get the performance stats, for a specified station
   def Performance.get_station_performance(tiplocs, deps_or_apps)


      # Get incoming tiplocs: a comma separated string
      tiplocs_string = tiplocs.upcase
      tiplocs_orig_array = tiplocs_string.split(',')
      
      tiplocs_final_array = tiplocs_orig_array

puts 'tiplocs_final_array'
p tiplocs_final_array
#       if (deps_or_apps == 'ARRIVALS')
         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_arrival)
#       else
#         @schedule = Location.where(:tiploc_code => tiplocs_final_array).order(:public_departure)
#       end      

      # get next 30mins of departures 
      after_range = 30.minute
      now = DateTime.now
      @range = Hash.new
      @range[:from] = now
      @range[:to] = now + after_range
      
      @schedule = @schedule.runs_between(@range[:from], @range[:to], false)

      timetables_array=[] 

puts 'got schedules'
puts 'n= '+@schedule.size.to_s

      n_live_deps = 0
      cum_secs_late = 0
      
      # get timetables
      @schedule.each do |schedule|

         # get the origin / destination - speed this up
         p schedule
         bs_uuid = schedule[:obj].basic_schedule_uuid

         
         # get matching movement updates, based on uuid, and tiploc
         live_movement_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).where( :msg_type => '0003' )

         # get matching cancel updates, based on uuid, and tiploc
         cancelled = false
         live_cancellation_msgs = LiveMsg.where( :basic_schedule_uuid => bs_uuid ).where( :msg_type => '0002' )      
         cancelled = true if live_cancellation_msgs.size() ==0

         if live_movement_msgs.size() ==1
            move_msg = JSON.parse(live_movement_msgs[0]['msg_body'])
            event_type = move_msg['event_type']
            variation_status = move_msg['variation_status']
            timetable_variation_mins = move_msg['timetable_variation'].to_i

            # TODO differentiate arrivals/departures

            # get the cum lateness
            if timetable_variation_mins!= nil                           
               diff_from_timetable_secs = 0         
               diff_from_timetable_secs = timetable_variation_mins*60  if move_msg['variation_status'] == 'LATE'               
               n_live_deps += 1
               cum_secs_late += diff_from_timetable_secs
            end
         end
      end
      
      # get the avg lateness
      avg_secs_late = nil
      avg_secs_late = cum_secs_late/n_live_deps if n_live_deps>0

      puts 'avg_secs_late = '+avg_secs_late.to_s
      # TODO dump to a table
   end

end
