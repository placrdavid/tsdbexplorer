require 'yaml'

# to fix problems related to logging on production / passenger
# http://stackoverflow.com/questions/9635527/no-log-messages-in-production-log
Rails.logger.instance_variable_get(:@logger).instance_variable_get(:@log_dest).sync = true if Rails.logger

# get the environment - set verbosity 
environment = Rails.env.to_s
verbosity = 'verbose'
verbosity = 'quiet' if environment=='production'

# load DB settings from yml file
db_settings = YAML.load_file(File.join(Rails.root.to_s+"/config/database.yml"))
host = db_settings[environment]['host']
port = db_settings[environment]['port']
dbname = db_settings[environment]['database']
username = db_settings[environment]['username']
pwd = db_settings[environment]['password']

# live tracker dir and files.
tsdb_settings = YAML.load_file(File.join(Rails.root.to_s+"/config/tsdbexplorer.yml"))
script_dir = tsdb_settings['TFL_TRACKER']['script_dir']
parser_script = tsdb_settings['TFL_TRACKER']['parser_script']
logfile = tsdb_settings['TFL_TRACKER']['logfile']

# networkrail feed credentials
networkrail_feedurl = tsdb_settings['TFL_TRACKER']['networkrail_feedurl']
networkrail_login = tsdb_settings['TFL_TRACKER']['networkrail_login']
networkrail_passcode = tsdb_settings['TFL_TRACKER']['networkrail_passcode']

scriptpath = Rails.root.to_s + '/'+script_dir+'/'+parser_script
logfilepath = Rails.root.to_s + '/'+script_dir+'/'+logfile

# the email of the sys admin, who should receive error emails
error_msg_recipient_email = tsdb_settings['TFL_TRACKER']['error_msg_recipient_email']
      
# formulate the cmd line string
ruby_cmdline_string = "ruby "+scriptpath.to_s+" '"+environment.to_s+"' '"+verbosity.to_s+"' '"+host.to_s+"' '"+port.to_s+"' '"+dbname.to_s+"' '"+username.to_s+"' '"+pwd.to_s+"' '"+networkrail_feedurl.to_s+"' '"+networkrail_login.to_s+"' '"+networkrail_passcode.to_s+"' '"+error_msg_recipient_email+"' >> "+logfilepath.to_s+""

# start a new thread within which run the background live logger script
Thread.new do    
   `#{ruby_cmdline_string}`
end
