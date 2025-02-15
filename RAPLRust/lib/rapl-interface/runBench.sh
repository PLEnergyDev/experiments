#!/bin/bash

# first argument is for stopping the logging from raspberry
# secound argument is for stopping the kill and burn script
# both arguments are strings and are set to "true" by default,
arg1=${1:-'true'}
arg2=${2:-'true'}
# set them to false stop the given feature.

# checking for invalid input
if ([ $arg1 != 'true' ] && [ $arg1 != 'false' ]) || ([ $arg2 != 'true' ] && [ $arg2 != 'false' ])
then
	echo "invalid input given, 'true' or 'false'"
	exit
fi

##########################
##### Pre Benchmarks #####
##########################

if [ $arg1 != 'false' ]
then
	#Send start signal to Raspberry PI - await confirmation from raspberry?
	echo "starting logger"
	bash utils/raspberry_logger.sh "start"
	sleep 10s
fi

if [ $arg2 != 'false' ]
then
	# Stop services and background processes
	bash utils/kill_and_burn.sh 0
fi

##########################
##### Run Benchmarks #####
##########################
echo "Starting benchmarks"

# Create dir for results
mkdir results

# Running all benchmarks
for f in benchRunners/*.sh; do
	bash "$f"
done

###########################
##### Post Benchmarks #####
###########################

if [ $arg2 != 'false' ]
then
	# starting services
	bash utils/kill_and_burn.sh 1


	# waiting for services to start
	echo "waiting 10 secounds for services to start"
	sleep 10s
fi

if [ $arg1 != 'false' ]
then
	# Send stop signal to Raspberry PI
	bash utils/raspberry_logger.sh "stop"
fi


if [ $arg1 != 'false' ]
then
	# Send results data to Raspberry PI
	bash utils/send_results_raspberry.sh
fi


