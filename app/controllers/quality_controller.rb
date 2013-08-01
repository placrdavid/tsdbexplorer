###########################################################
# David Mountain, david.mountain@placr.co.uk (c) Placr Ltd
# Jul 2013
# Quality checks for live trains server
###########################################################

require 'json'
require 'yaml'

class QualityController < ApplicationController
   
   # Quality test - rate of missing tiplocs
   def rate_of_missing_tiplocs
      # expected n, from yml
      expected_n = $CONFIG["COMPLETENESS_TESTS_EXPECTED_VALUES"]['expected_n_tiplocs']
      # actual n, from DB
      actual_n = Tiploc.count
      # rate, pass, etc
      rate_of_missing = ((expected_n.to_f - actual_n.to_f) / expected_n.to_f).round(2)
      acceptable_metric_value = $CONFIG["ACCEPTABLE_QUALITY_METRIC_VALUES"]['rate_of_missing_tiplocs']
      pass = false
      if rate_of_missing < acceptable_metric_value
        pass = true
      end
      # report as json
      test_results_hash = Hash.new
      test_results_hash = { :test => 'rate of missing tiplocs', :actual_n => actual_n, 
      	:expected_n => expected_n, :rate_of_missing => rate_of_missing, 
      	:acceptable_metric_value => acceptable_metric_value, :pass => pass }
      output_json = test_results_hash.to_json
      send_data output_json, :type => :json, :disposition => 'inline'
   end

   # Quality test - rate of missing locations
   def rate_of_missing_locations
      # expected n, from yml
      expected_n = $CONFIG["COMPLETENESS_TESTS_EXPECTED_VALUES"]['expected_n_locations']
      # actual n, from DB
      actual_n = Location.count
      # rate, pass, etc
      rate_of_missing = ((expected_n.to_f - actual_n.to_f) / expected_n.to_f).round(2)
      acceptable_metric_value = $CONFIG["ACCEPTABLE_QUALITY_METRIC_VALUES"]['rate_of_missing_locations']
      pass = false
      if rate_of_missing < acceptable_metric_value
        pass = true
      end
      # report as json
      test_results_hash = Hash.new
      test_results_hash = { :test => 'rate of missing locations', :actual_n => actual_n, 
      	:expected_n => expected_n, :rate_of_missing => rate_of_missing, 
      	:acceptable_metric_value => acceptable_metric_value, :pass => pass }
      output_json = test_results_hash.to_json
      send_data output_json, :type => :json, :disposition => 'inline'
   end

   # Quality test - rate of missing basic_schedules
   def rate_of_missing_basic_schedules
      # expected n, from yml
      expected_n = $CONFIG["COMPLETENESS_TESTS_EXPECTED_VALUES"]['expected_n_basic_schedules']
      # actual n, from DB
      actual_n = BasicSchedule.count
      # rate, pass, etc
      rate_of_missing = ((expected_n.to_f - actual_n.to_f) / expected_n.to_f).round(2)
      acceptable_metric_value = $CONFIG["ACCEPTABLE_QUALITY_METRIC_VALUES"]['rate_of_missing_basic_schedules']
      pass = false
      if rate_of_missing < acceptable_metric_value
        pass = true
      end
      # report as json
      test_results_hash = Hash.new
      test_results_hash = { :test => 'rate of missing basic schedules', :actual_n => actual_n, 
      	:expected_n => expected_n, :rate_of_missing => rate_of_missing, 
      	:acceptable_metric_value => acceptable_metric_value, :pass => pass }
      output_json = test_results_hash.to_json
      send_data output_json, :type => :json, :disposition => 'inline'
   end

   # Quality test - rate of excess tiplocs
   def rate_of_excess_tiplocs
      # expected n, from yml
      expected_n = $CONFIG["COMPLETENESS_TESTS_EXPECTED_VALUES"]['expected_n_tiplocs']
      # actual n, from DB
      actual_n = Tiploc.count
      # rate, pass, etc
      rate_of_excess = (( actual_n.to_f - expected_n.to_f) / expected_n.to_f).round(2)
      acceptable_metric_value = $CONFIG["ACCEPTABLE_QUALITY_METRIC_VALUES"]['rate_of_excess_tiplocs']
      pass = false
      if rate_of_excess < acceptable_metric_value
        pass = true
      end
      # report as json
      test_results_hash = Hash.new
      test_results_hash = { :test => 'rate of excess tiplocs', :actual_n => actual_n, 
      	:expected_n => expected_n, :rate_of_excess => rate_of_excess, 
      	:acceptable_metric_value => acceptable_metric_value, :pass => pass }
      output_json = test_results_hash.to_json
      send_data output_json, :type => :json, :disposition => 'inline'
   end

   # Quality test - rate of excess locations
   def rate_of_excess_locations
      # expected n, from yml
      expected_n = $CONFIG["COMPLETENESS_TESTS_EXPECTED_VALUES"]['expected_n_locations']
      # actual n, from DB
      actual_n = Location.count
      # rate, pass, etc
      rate_of_excess = ((actual_n.to_f - expected_n.to_f) / expected_n.to_f).round(2)
      acceptable_metric_value = $CONFIG["ACCEPTABLE_QUALITY_METRIC_VALUES"]['rate_of_excess_locations']
      pass = false
      if rate_of_excess < acceptable_metric_value
        pass = true
      end
      # report as json
      test_results_hash = Hash.new
      test_results_hash = { :test => 'rate of excess locations', :actual_n => actual_n, 
      	:expected_n => expected_n, :rate_of_excess => rate_of_excess, 
      	:acceptable_metric_value => acceptable_metric_value, :pass => pass }
      output_json = test_results_hash.to_json
      send_data output_json, :type => :json, :disposition => 'inline'
   end

   # Quality test - rate of excess basic_schedules
   def rate_of_excess_basic_schedules
      # expected n, from yml
      expected_n = $CONFIG["COMPLETENESS_TESTS_EXPECTED_VALUES"]['expected_n_basic_schedules']
      # actual n, from DB
      actual_n = BasicSchedule.count
      # rate, pass, etc
      rate_of_excess = ((actual_n.to_f - expected_n.to_f) / expected_n.to_f).round(2)
      acceptable_metric_value = $CONFIG["ACCEPTABLE_QUALITY_METRIC_VALUES"]['rate_of_excess_basic_schedules']
      pass = false
      if rate_of_excess < acceptable_metric_value
        pass = true
      end
      # report as json
      test_results_hash = Hash.new
      test_results_hash = { :test => 'rate of excess basic schedules', :actual_n => actual_n, 
      	:expected_n => expected_n, :rate_of_excess => rate_of_excess, 
      	:acceptable_metric_value => acceptable_metric_value, :pass => pass }
      output_json = test_results_hash.to_json
      send_data output_json, :type => :json, :disposition => 'inline'
   end

   
end
