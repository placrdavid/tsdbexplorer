###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Jul 2012
# A live departures controller
###########################################################

class LiveController < ApplicationController


   # Return all known live updates for a station, in json format
   def stations_updates_json

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

end

