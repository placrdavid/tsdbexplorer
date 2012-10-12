#!/usr/bin/env ruby

###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Oct 2012
# Parses the live train movement feed from network rail
#   and writes the incoming messages to redis
###########################################################

require 'rubygems'
require 'eventmachine'
require 'json'
require 'yaml'
require "date"
require 'redis'

# flush comments to stdout
STDOUT.sync = true 

# GLOBAL PARAMS
# rails env, verbosity
@environment 
@quiet    
@error_msg_recipient_email

# network rail params
@networkrail_feedurl 
@networkrail_login 
@networkrail_passcode   

# stores the current msg - for debug diagnostics
@current_msg
# stores the time we last received a msg from network rail
@timelastmsg

# the redis server
@redis
# the DB name - used by redis to differentiate different stacks
@dbname 

=begin
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

=end

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

# Poller module: parses the live feed
module Poller

   include EM::Protocols::Stomp

   # initialisation steps once we have a connection to apachemq feed
   def connection_completed
      
      #ruby live_feed_to_redis.rb development quiet live_trains networkrail_feedurl networkrail_login networkrail_passcode error_msg_recipient_email live_feeds >> logfilepath.to_s

      @environment = ARGV[0]
      @quiet = false      
      @quiet = true if ARGV[1].downcase == 'quiet'
      @dbname = ARGV[2]
      @networkrail_login = ARGV[4]
      @networkrail_passcode = ARGV[5] 
      @error_msg_recipient_email = ARGV[6] 
      subscribed_feeds_string = ARGV[7] 
      @subscribed_feeds = subscribed_feeds_string.split(',')
      
      @redis = Redis.new

      # authent / connect to feed - credentials loaded from a yml
      puts Time.now.to_s+': connecting to feed' unless @quiet
      connect :login => @networkrail_login, :passcode => @networkrail_passcode
      puts Time.now.to_s+': connected to feed' unless @quiet

   end

   # event: msg received from live feed
   def receive_msg msg
   
      puts Time.now.to_s+': msg received' unless @quiet      
      if msg.command == "CONNECTED"

         puts Time.now.to_s+': connected to live trains server, subscribing to feeds' unless @quiet
         # subscribe to all listed feeds
         @subscribed_feeds.each do |subscribed_feed|
            puts 'subscribing to '+subscribed_feed.to_s
            subscribe subscribed_feed.to_s
         end
      else

         # any exceptions in this loop are caught and shouldn't stop the script functioning
         begin

            # serialise the containing msg body from json
            msg_list = JSON.parse(msg.body)
            # for each individual msg
            msg_list.each do |indiv_msg|
            
               # log when we received last msg
               @timelastmsg = Time.now

               # store the current msg for debug diagnostics
               @current_msg = indiv_msg
               puts Time.now.to_s+': individual msg = ' unless @quiet
               p @current_msg
               
               # V1, store all messages as a list of strings, with a single key
               # use RPUSH to add a new element to the tail of the list
               # dump the msg into redis
               redis_livefeed_keyname = @dbname+'_'+@environment
               @redis.lpush(redis_livefeed_keyname,indiv_msg.to_json)
               puts Time.now.to_s+': pushed into redis' unless @quiet
               

            end  #    msg_list.each do |indiv_msg|
           
         # this allows the loop to continue, whilst emailing us an alert
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

   @networkrail_feedurl = ARGV[3]
   puts Time.now.to_s+': @networkrail_feedurl = '+@networkrail_feedurl  unless @quiet
   
   # EventMachine method - initiates a TCP connection to the remote server and sets up event-handling for the connection
   EM.connect @networkrail_feedurl, 61618, Poller
}
