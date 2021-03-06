# The wrapper script for the live feed parser
# Jul 2012
# David Mountain david.mountain@placr.co.uk
# Checks 
#  (1) is script running
#  (2) is live data stale
# and shuts down / restarts the script if necess
# Run on a cron job, every n minute(s)

require 'yaml'
gem 'pg', '= 0.13.2'
require "pg"
require 'time'

# flush out output
STDOUT.sync = true 

@verbose_cleaning = false
# to run script
#  ruby live_feed_runner.rb production verbose '/home/dmm/tfl_live_tsdb/tsdbexplorer'

@conn # the DB connection
# how long before we consider data 'stale'
stale_limit_secs = 30

# open the DB connection
def open_db_connection(host, dbname, port, username, pwd)
   # Connection to rails DB
   @conn = PGconn.open(:host=> host, :user => username, :password => pwd, :dbname => dbname, :port => port)
   puts Time.now.to_s+': connected to DB' unless @quiet
end

# close the DB connection
def close_db_connection()
   @conn.finish
   puts Time.now.to_s+': disconnected from DB' unless @quiet
end
@tracked_trains_expiry = '1 day'

#@station_updates_moving_trains_expiry = '30 minutes'
#@station_updates_activated_trains_expiry = '4 hours'

@msg_0003_expiry = '30 minutes'
@msg_all_expiry = '4 hours'


# prepare sql statements
def prepare_sql

   # delete tracked trains older than specified time period (we assume that no train journeys are longer than 24hrs)
   delete_legacy_trackedtrains_sql = "delete from tracked_trains where origin_dep_timestamp < now() - interval '"+@tracked_trains_expiry+"'"
   @conn.prepare("delete_legacy_trackedtrains_plan", delete_legacy_trackedtrains_sql)
   select_legacy_trackedtrains_sql = "select * from tracked_trains where origin_dep_timestamp < now() - interval '"+@tracked_trains_expiry+"'"
   @conn.prepare("select_legacy_trackedtrains_plan", select_legacy_trackedtrains_sql)

   # delete live 0003 messages, older than specified time period
   delete_legacy_0003_msgs_sql = "delete from live_msgs where updated_at < now() - interval '"+@msg_0003_expiry+"' and msg_type = '0003'"
   @conn.prepare("delete_legacy_0003_msgs_plan",delete_legacy_0003_msgs_sql)
   select_legacy_0003_msgs_sql = "select * from live_msgs where updated_at < now() - interval '"+@msg_0003_expiry+"' and msg_type = '0003'"
   @conn.prepare("select_legacy_0003_msgs_plan",select_legacy_0003_msgs_sql)

   # delete all stale messages after 4 hrs
   delete_legacy_all_msgs_sql = "delete from live_msgs where updated_at < now() - interval '"+@msg_all_expiry+"'"
   @conn.prepare("delete_legacy_all_msgs_plan",delete_legacy_all_msgs_sql)
   select_legacy_all_msgs_sql = "delete from live_msgs where updated_at < now() - interval '"+@msg_all_expiry+"'"
   @conn.prepare("select_legacy_all_msgs_plan",select_legacy_all_msgs_sql)


=begin
   # delete station_updates for MOVING trains, older than specified time period
   delete_legacy_stationupdates_for_moving_trains_sql = "delete from station_updates where updated_at < now() - interval '"+@station_updates_moving_trains_expiry+"' and variation_status not like 'NO REPORT'"
   @conn.prepare("delete_legacy_stationupdates_for_moving_trains_plan",delete_legacy_stationupdates_for_moving_trains_sql)
   select_legacy_stationupdates_for_moving_trains_sql = "select * from station_updates where updated_at < now() - interval '"+@station_updates_moving_trains_expiry+"' and variation_status not like 'NO REPORT'"
   @conn.prepare("select_legacy_stationupdates_for_moving_trains_plan",select_legacy_stationupdates_for_moving_trains_sql)

   # delete station_updates for ACTIVE BUT NOT YET MOVING trains, older than specified time period
   delete_legacy_stationupdates_for_activated_trains_sql = "delete from station_updates where updated_at < now() - interval '"+@station_updates_activated_trains_expiry+"' and variation_status like 'NO REPORT'"
   @conn.prepare("delete_legacy_stationupdates_for_activated_trains_plan",delete_legacy_stationupdates_for_activated_trains_sql)
   select_legacy_stationupdates_for_activated_trains_sql = "delete from station_updates where updated_at < now() - interval '"+@station_updates_activated_trains_expiry+"' and variation_status like 'NO REPORT'"
   @conn.prepare("select_legacy_stationupdates_for_activated_trains_plan",select_legacy_stationupdates_for_activated_trains_sql)

=end


   # get time of last update -   TODO from tracked trains?
   get_time_last_update_sql = "select updated_at from live_msgs order by updated_at desc limit 1"
   @conn.prepare("get_time_last_update_plan", get_time_last_update_sql)

end

# get the time of the last update TODO from tracked trains?
def time_last_update()
#=begin
   res_latest_update = @conn.exec_prepared("get_time_last_update_plan", []) 
   if res_latest_update.count <=0
      return nil
   else
      return Time.parse(res_latest_update[0]['updated_at'])
   end
#=end
end

# remove any tracked trains that were activated a long time ago
def clean_tracked_trains

   # verbose cleaning - for debug
   if @verbose_cleaning
      trains_to_clean = @conn.exec_prepared("select_legacy_trackedtrains_plan", [])     
      puts ""+trains_to_clean.count.to_s+" tracked trains older than "+@tracked_trains_expiry+" to clean from DB"
      trains_to_clean.each { |train_to_clean| 
         puts "---------------------------------------------------------------------"
         puts "train with train_service_code "+train_to_clean['train_service_code'].to_s+" will be purged"
         p train_to_clean
         puts "---------------------------------------------------------------------"
      }
   end
   @conn.exec_prepared("delete_legacy_trackedtrains_plan", [])     
end

=begin
# remove any aged station updates
def clean_station_updates
   # verbose cleaning - for debug
   if @verbose_cleaning
      updates_to_clean = @conn.exec_prepared("select_legacy_stationupdates_for_moving_trains_plan", [])     
      puts ""+updates_to_clean.count.to_s+" station_updates for moving trains older than "+@station_updates_moving_trains_expiry+" to clean from DB"
      updates_to_clean.each { |update_to_clean| 
         puts "---------------------------------------------------------------------"
         puts "station update for station tiploc "+update_to_clean['tiploc_code']+" with train_service_code "+update_to_clean['train_service_code'].to_s+" will be purged"
         p update_to_clean
         puts "---------------------------------------------------------------------"
      }
   end
   @conn.exec_prepared("delete_legacy_stationupdates_for_moving_trains_plan", [])     
      # verbose cleaning - for debug
   if @verbose_cleaning
      updates_to_clean = @conn.exec_prepared("select_legacy_stationupdates_for_activated_trains_plan", [])     
      puts ""+updates_to_clean.count.to_s+" station_updates for activated trains older than "+@station_updates_activated_trains_expiry+" to clean from DB"
      updates_to_clean.each { |update_to_clean| 
         puts "---------------------------------------------------------------------"
         puts "station update for station tiploc "+update_to_clean['tiploc_code']+" with train_service_code "+update_to_clean['train_service_code'].to_s+" will be purged"
         p update_to_clean
         puts "---------------------------------------------------------------------"
      }
   end
   @conn.exec_prepared("delete_legacy_stationupdates_for_activated_trains_plan", [])     
end
=end


# remove any stale live msgs
def clean_live_msgs
   # verbose cleaning - for debug
   if @verbose_cleaning
      msgs0003_to_clean = @conn.exec_prepared("select_legacy_0003_msgs_plan", [])     
      puts ""+msgs0003_to_clean.count.to_s+" live 0003 msgs older than "+@msg_0003_expiry+" to clean from DB"
      msgs0003_to_clean.each { |msg0003_to_clean| 
         puts "---------------------------------------------------------------------"
         puts "Purging the following 0003 msg"
         p msg0003_to_clean
         puts "---------------------------------------------------------------------"
      }
   end
   @conn.exec_prepared("delete_legacy_0003_msgs_plan", [])     
   
   # verbose cleaning - for debug
   if @verbose_cleaning
      msgs_to_clean = @conn.exec_prepared("select_legacy_all_msgs_sql", [])     
      puts ""+msgs_to_clean.count.to_s+" live messages (all types) older than "+@msg_other_expiry+" to clean from DB"
      msgs_to_clean.each { |msg_to_clean| 
         puts "---------------------------------------------------------------------"
         puts "Purging the following msg"
         p msg_to_clean
         puts "---------------------------------------------------------------------"
      }
   end
   @conn.exec_prepared("delete_legacy_all_msgs_plan", [])     
end

# clean up all live feeds
def clean_live_feed
   clean_tracked_trains()
#   clean_station_updates()
   clean_live_msgs()

end

puts 'new comment'

# get the environment and verbosity from cmd line
environment = ARGV[0]
verbosity = 'verbose'
verbosity = 'quiet' if ARGV[1].downcase == 'quiet'
rails_root = ARGV[2]

# load DB settings from yml file
db_settings = YAML.load_file(File.join(rails_root.to_s+"/config/database.yml"))
host = db_settings[environment]['host']
port = db_settings[environment]['port']
dbname = db_settings[environment]['database']
username = db_settings[environment]['username']
pwd = db_settings[environment]['password']

# open DB connection, prep SQL
open_db_connection(host, dbname, port, username, pwd)
prepare_sql()

# live tracker dir and files.
tsdb_settings = YAML.load_file(File.join(rails_root.to_s+"/config/tsdbexplorer.yml"))
script_dir = tsdb_settings['TFL_TRACKER']['script_dir']
parser_script = tsdb_settings['TFL_TRACKER']['parser_script']
logfile = tsdb_settings['TFL_TRACKER']['logfile']
live_feeds = tsdb_settings['TFL_TRACKER']['live_feeds']
#puts 'live feeds '
#p live_feeds

# networkrail feed credentials
networkrail_feedurl = tsdb_settings['TFL_TRACKER']['networkrail_feedurl']
networkrail_login = tsdb_settings['TFL_TRACKER']['networkrail_login']
networkrail_passcode = tsdb_settings['TFL_TRACKER']['networkrail_passcode']

scriptpath = rails_root.to_s + '/'+script_dir+'/'+parser_script
logfilepath = rails_root.to_s + '/'+script_dir+'/'+environment+'-'+logfile

# the email of the sys admin, who should receive error emails
error_msg_recipient_email = tsdb_settings['TFL_TRACKER']['error_msg_recipient_email']

log_movements = tsdb_settings['TFL_TRACKER']['log_movements'] 
            
# formulate the cmd line string
ruby_cmdline_string = "ruby "+scriptpath.to_s+" '"+environment.to_s+"' '"+verbosity.to_s+"' '"+host.to_s+"' '"+port.to_s+"' '"+dbname.to_s+"' '"+username.to_s+"' '"+pwd.to_s+"' '"+networkrail_feedurl.to_s+"' '"+networkrail_login.to_s+"' '"+networkrail_passcode.to_s+"' '"+error_msg_recipient_email+"' '"+live_feeds.to_s+"' '"+log_movements.to_s+"' >> "+logfilepath.to_s+" &"
puts ruby_cmdline_string

# get the PID(s), or an empty string ('') if script is not running 
# *could* be multiple processes, so get as an array
PID=`ps -eo 'tty pid args' | grep '#{scriptpath}' | grep -v grep | tr -s ' ' | cut -f2 -d ' '`
PID_array = PID.split(' ')
# if we are running multiple versions of the script - flag this up
if PID_array.count>=2
   puts Time.now.to_s+': currently running '+PID_array.count.to_s+' versions of the '+parser_script+' script. Should not happen! ' unless @quiet
end

# test if the updates are stale
latest_update_stale=false
last_update_t = time_last_update()
secs_since_last_update = stale_limit_secs+1
secs_since_last_update = Time.now - last_update_t unless last_update_t.nil?
latest_update_stale = true if secs_since_last_update > stale_limit_secs

# record t/f if script is running
script_running=false
script_running=true unless PID=='' || PID.nil?

# check conditions for restarting script
restart_script = false

# if (1) script running, but updates stale, or (2) we are running multiple versions, kill script(s), and restart
if (latest_update_stale && script_running) || PID_array.count>=2
   PID_array.each do |pid|
      kill_pid_cmd = 'kill -9 '+pid.to_s
      `#{kill_pid_cmd}`
   end
   if last_update_t.nil?
      puts Time.now.to_s+': script must be shut down and restarted: script_running = '+script_running.to_s+
      ' and latest_update_stale = '+latest_update_stale.to_s+' (last_update_t is nil -> no updates in DB?!?)' unless @quiet
   else
      puts Time.now.to_s+': script must be shut down and restarted: script_running = '+script_running.to_s+
      ' and latest_update_stale = '+latest_update_stale.to_s+' ('+secs_since_last_update.to_s+' secs since last update)' unless @quiet
   end

   restart_script = true
end

# if script was not running, restart
unless script_running
   puts Time.now.to_s+': script was not running - must restart' unless @quiet
   restart_script = true
end

# if required, restart script
if restart_script
  puts Time.now.to_s+': restarting script' unless @quiet
   `#{ruby_cmdline_string}`
else
   puts Time.now.to_s+': updates are fresh and script is running as expected. No restart required' unless @quiet
end

# clean up our filthy tables
clean_live_feed()

# close the DB connection
close_db_connection()

