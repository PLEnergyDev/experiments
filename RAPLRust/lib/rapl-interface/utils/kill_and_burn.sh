#!/bin/bash

# List of services to stop
declare -a services=(
    "apparmor"
    "apport"
    "cron"
    "dbus"
    "multipath-tools"
    "open-iscsi"
    "plymouth"
    "plymouth-log"
    "rsync"
    "ssh"
    "ufw"
    "unattended-upgrades"
    "NetworkManager.service"
    "/etc/init.d/ssh"
)

declare -a processes=(
    "sshd"
)


start_stop_function() {
    local cmd="$1"
    for service in "${services[@]}"; do
        sudo systemctl $cmd $service
    done
}

kill_processes() {
   for process in "${processes[@]}"; do
      sudo pkill -f $process
   done
}

if [ "$1" == "0" ]; then
  START_STOP="stop"
  ENABLE_DISABLE="disable"
  echo "Shutting down all services"
  start_stop_function $START_STOP
 # start_stop_function $ENABLE_DISABLE
  echo "All unnecessary services have been stopped and disabled"
  kill_processes
  echo "All unnecessary processes have been stopped"
elif [ "$1" == "1" ]; then
  START_STOP="start"
  ENABLE_DISABLE="enable" 
  echo "Starting all services yahoo"
  start_stop_function $ENABLE_DISABLE
  start_stop_function $START_STOP
  echo "All usual services have been enabled and started"
else
  echo "$1 is an invalid argument. Valid arguments: [1, 0]."
  exit 1
fi

