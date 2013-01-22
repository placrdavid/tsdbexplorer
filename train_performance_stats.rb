#
# Train performance metrics
#
# Calculate and store "current" values averaged over a recent timespan.

# usage
#    ruby train_performance_stats.rb development normal



quiet = (ARGV.include? 'quiet')

#load the full rails environment 
#See http://stackoverflow.com/questions/293302/how-do-i-run-ruby-tasks-that-use-my-rails-models and
#    http://shifteleven.com/articles/2006/10/08/loading-your-rails-environment-into-a-script
puts 'loading rails env'
ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development' 
puts "Initialising rails environment " + ENV['RAILS_ENV'] unless quiet
require "#{File.dirname('.')}/config/environment"


# performance stats
require Rails.root + "lib/performance.rb"

runStartTime = Time.now

# array of stations we wish to get performance stats about
crs_tiplocs = {"LST" => 'LIVST',"OLD" => 'OLDST',"MOG" => 'MRGT',"SDC" => 'SHRDHST',"HOX" => 'HOXTON',"FST" => 'FENCHRS',"CST" => 'CANONST',"ZFD" => 'FRNDNLT',"BET" => 'BTHNLGR',"ZWL" => 'WCHAPEL',"CTK" => 'CTMSLNK',"BFR" => 'BLFR',"HGG" => 'HAGGERS',"LBG" => 'LNDNBDG,LNDNBD,LNDNBDE,LNDNBAL,LNDNB9,LNDNB10,LNDNB11,LNDNB12,LNDNB13,LNDNB14,LNDNB1,LNDNB16,LNDN490',"CBH" => 'CAMHTH',"SDE" => 'SHADWEL',"EXR" => 'ESSEXRD',"WAE" => 'WLOE',"DLJ" => 'DALS',"LOF" => 'LONFLDS',"WPE" => 'WAPPING',"KGX" => 'KNGX',"DLK" => 'DALSKLD',"WAT" => 'WATRLMN'}
crs_tiplocs.each do |crs, tiploc_code_csv|
   puts 'getting stats for crs '+crs+' tiplocs '+tiploc_code_csv
   Performance.get_station_performance(tiploc_code_csv, 'departures')

end

puts 'got performance stats'

puts "Execution time: "  + (Time.now - runStartTime).to_s
puts "DONE" unless quiet


         
