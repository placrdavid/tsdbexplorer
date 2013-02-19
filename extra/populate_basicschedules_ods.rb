# Jan 2013
# David Mountain david.mountain@placr.co.uk
# Populates the origins and destinations of basic schedule records. A flattening trick to improve performance

require "yaml"
require "pg"
require 'time'

# to run script
#  ruby populate_basicschedules_ods.rb production verbose '/home/dmm/tfl_live_tsdb/tsdbexplorer'

@conn # the DB connection

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


# prepare sql statements
def prepare_sql

   # update the origin tiploc
   set_origin_tiploc_sql = "update basic_schedules set origin_tiploc = locations.tiploc_code from locations where basic_schedules.uuid = locations.basic_schedule_uuid and locations.location_type = 'LO'"
   @conn.prepare("set_origin_tiploc_plan", set_origin_tiploc_sql)

   # update the destination tiploc
   set_destin_tiploc_sql = "update basic_schedules set destin_tiploc = locations.tiploc_code from locations where basic_schedules.uuid = locations.basic_schedule_uuid and locations.location_type = 'LT'"
   @conn.prepare("set_destin_tiploc_plan", set_destin_tiploc_sql)

   # update the origin name
   set_origin_name_sql = "update basic_schedules set origin_name = tiplocs.tps_description from tiplocs where origin_tiploc = tiplocs.tiploc_code"
   @conn.prepare("set_origin_name_plan", set_origin_name_sql)

   # update the destination name
   set_destin_name_sql = "update basic_schedules set destin_name = tiplocs.tps_description from tiplocs where destin_tiploc = tiplocs.tiploc_code"
   @conn.prepare("set_destin_name_plan", set_destin_name_sql)


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


@conn.exec_prepared("set_origin_tiploc_plan", []) 
@conn.exec_prepared("set_destin_tiploc_plan", []) 
@conn.exec_prepared("set_origin_name_plan", []) 
@conn.exec_prepared("set_destin_name_plan", []) 
