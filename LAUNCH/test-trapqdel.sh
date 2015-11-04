#!/bin/bash
# traptest.sh

trap "echo Booh!" SIGINT "echo Booh!" SIGTERM
echo "pid is $$"

while :        # This is the same as "while true".
do
    sleep 60  # This script is not really doing anything.
done

