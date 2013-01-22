#!/bin/sh
#Run the train_performance_stats.rb file
# Loads settings from ../bash_settings.txt, sets ruby and gemset using RVM if installed/defined
# This shell script can be run from a cron job, e.g. every 15mins

cd $(dirname $0) #change directory to the diretory this file is in

# load our settings file
#. ./../bash_settings.txt
rails_env_value='development'
verbosity_value='normal'
RVM_VERSION='1.9.3'
GEMSET_VERSION='ruby193rails3'
# check if RVM is installed, and make it available
RVM_INSTALLED=false
# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
  printf "Loaded RVM from a user install\n"
  RVM_INSTALLED=true
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
  printf "Loaded RVM from a root install\n"
  RVM_INSTALLED=true
else
  printf "No RVM installation found - system ruby and gemset will be used.\n"
fi

# use the rvm and gemset defined in settings.txt, if RVM is installed.
if $RVM_INSTALLED ; then
  rvm use $RVM_VERSION
  rvm gemset use $GEMSET_VERSION
  printf "using rvm ruby version $RVM_VERSION and gemset rvm $GEMSET_VERSION\n"
fi

# rails_env and verbosity values CAN be defined in /../bash_settings.txt
ruby train_performance_stats.rb $rails_env_value $verbosity_value >> train_performance_stats.log 2>&1
