require 'yaml'

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

# live_parser_running ? 
process_running = false

# check if the pifile exists
#pidfilename = tsdb_settings['TFL_TRACKER']['pidfile']
#pid_file_path = Rails.root.to_s + '/'+script_dir+'/'+pidfilename
#puts 'pid file  = '+pid_file_path.to_s
#file_exists = File.exists?(pid_file_path)
#puts 'file_exists  = '+file_exists.to_s

# if file exists - get the pid, check if its running
#if file_exists 
#   puts 'THE FILE EXISTS'
#   lines = IO.readlines(pid_file_path)
#   pid = lines.first
#   puts 'pid = '+pid.to_s
#end

# start a new thread within which run the background live logger script
Thread.new do 

# delete the file if it exists  
#File.delete(pid_file_path) if File.exists?(pid_file_path)
#puts 'deleted the  file'
#pid = Process.pid

#   puts 'started a new thread with process id = '+pid.to_s
#puts 'got the  process id - its  '+pid.to_s
# Create a new file and write to it  
#File.open(pid_file_path, 'w') do |f2|  
#   # use "\n" for two lines of text  
#   f2.puts pid.to_s
#   puts 'saved the  rpocess id to file'
#end  
   
   `#{ruby_cmdline_string}`
   # shut down when rails stops
   # now it is running, store the pid, in 


end
