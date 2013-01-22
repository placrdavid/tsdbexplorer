#
# Train performance metrics
#
# Calculate and store "current" values averaged over a recent timespan.

# usage
#    ruby train_performance_stats.rb development normal


runStartTime = Time.now

quiet = (ARGV.include? 'quiet')

#load the full rails environment 
#See http://stackoverflow.com/questions/293302/how-do-i-run-ruby-tasks-that-use-my-rails-models and
#    http://shifteleven.com/articles/2006/10/08/loading-your-rails-environment-into-a-script
puts 'loading rails env'
ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development' 
puts "Initialising rails environment " + ENV['RAILS_ENV'] unless quiet
require "#{File.dirname('.')}/config/environment"


puts 'starting loop'


# performance stats
require Rails.root + "lib/performance.rb"
Performance.test
puts 'ran the test'

Performance.get_station_performance('GOSPLOK', 'departures')
puts 'got stoke performance stats'


puts "Execution time: "  + (Time.now - runStartTime).to_s

puts "DONE" unless quiet


         
