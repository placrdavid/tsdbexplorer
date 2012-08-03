#!/bin/sh
# Runs the live feed parser

cd $(dirname $0) #change directory to the diretory this file is in

# load our settings file
. ./bash_settings.txt

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

# define rails_env and verbosity values in settings.txt
export RAILS_ENV=$rails_env_value
export VERBOSITY=$verbosity_value
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

ruby live_feed_runner.rb $RAILS_ENV $VERBOSITY $DIR >> live_feed_runner.log
