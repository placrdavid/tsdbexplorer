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

# Poller module: parses the live feed
module Poller

   include EM::Protocols::Stomp

   # initialisation steps once we have a connection to apachemq feed
   def connection_completed
      
      #ruby live_feed_to_redis.rb development quiet live_trains networkrail_feedurl networkrail_login networkrail_passcode error_msg_recipient_email live_feeds >> logfilepath.to_s

      @environment = ARGV[0]
      puts '@environment = '+@environment .to_s
      @quiet = false      
      @quiet = true if ARGV[1].downcase == 'quiet'
      puts '@quiet = '+@quiet .to_s
      @dbname = ARGV[2]
      puts '@dbname = '+@dbname .to_s
      @networkrail_login = ARGV[4]
      puts '@networkrail_login = '+@networkrail_login .to_s
      @networkrail_passcode = ARGV[5] 
      puts '@networkrail_passcode = '+@networkrail_passcode .to_s
      @error_msg_recipient_email = ARGV[6] 
      puts '@error_msg_recipient_email = '+@error_msg_recipient_email .to_s
      subscribed_feeds_string = ARGV[7] 
      puts 'subscribed_feeds_string = '+subscribed_feeds_string .to_s
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
               
               # dump all messages to a single list - slow?
               #redis_livefeed_keyname = @dbname                           
               #@redis.lpush(redis_livefeed_keyname,@current_msg.to_json)
#"header\":{\"msg_type\":\"0003\",\"source_dev_id\":\"\",\"user_id\":\"\",\"original_data_source\":\"SMART\",\"msg_queue_timestamp\":\"1350040304000\

#               msg_type = indiv_msg['header']['1350040304000']  
               keyname = indiv_msg['header']['msg_queue_timestamp']
               timestamp = indiv_msg['header']['msg_queue_timestamp'] 
               @redis.zadd(timestamp, timestamp, @current_msg.to_json)
               
               #
               
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
   puts '@networkrail_feedurl = '+@networkrail_feedurl.to_s

   puts Time.now.to_s+': @networkrail_feedurl = '+@networkrail_feedurl  unless @quiet
   
   # EventMachine method - initiates a TCP connection to the remote server and sets up event-handling for the connection
   EM.connect @networkrail_feedurl, 61618, Poller
}
