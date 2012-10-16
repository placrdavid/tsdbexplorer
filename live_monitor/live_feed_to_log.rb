#!/usr/bin/env ruby

###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Oct 2012
# Parses the live train movement feed from network rail
#   and writes the incoming activation messages to a log
###########################################################

require 'rubygems'
require 'eventmachine'
require 'json'
require 'yaml'
require "date"
#require 'redis'

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
#@redis
# the DB name - used by redis to differentiate different stacks
@dbname 

# Poller module: parses the live feed
module Poller

   include EM::Protocols::Stomp

   # initialisation steps once we have a connection to apachemq feed
   def connection_completed
      
      #ruby live_feed_to_live.rb development quiet live_trains networkrail_feedurl networkrail_login networkrail_passcode error_msg_recipient_email live_feeds >> logfilepath.to_s

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
      
      #@redis = Redis.new

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

            puts Time.now.to_s+': msg.body ...... ' unless @quiet
            puts '-----------------------------------------' unless @quiet
            p msg.body
            puts '-----------------------------------------' unless @quiet

            # serialise the containing msg body from json
            msg_list = JSON.parse(msg.body)
            # for each individual msg

            if @timelastmsg.nil?
               puts '=============================================================='
               puts 'Previous msg time was nil - script (re)started?'
            else
               puts Time.now.to_s+': timelastmsg = '+@timelastmsg.to_s unless @quiet
               interval = Time.now - @timelastmsg
               puts Time.now.to_s+': time since last msg = '+interval.to_s+' secs' unless @quiet
               # report if more than 60secs has elapsed
               if interval > 60
                  puts Time.now.to_s+': |||||||||||||||||||||||| Failed connection? ||||||||||||||||||||||||' unless @quiet
               end
            end
            # log when we received last msg
            @timelastmsg = Time.now


            msg_list.each do |indiv_msg|

               # store the current msg for debug diagnostics
               @current_msg = indiv_msg

               msg_type = indiv_msg['header']['msg_type']
#               if msg_type == '0001'                     
               puts Time.now.to_s+': individual msg of type '+msg_type.to_s unless @quiet
               p @current_msg
#               end
               puts Time.now.to_s+': Finished handling individual msg'      

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

      puts Time.now.to_s+': End of receive_msg function'      
      
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
