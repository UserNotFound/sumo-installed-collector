#!/bin/bash
set -e

# Tail the collector log file, since I can't find a way to send it to stdout
tail -F /opt/SumoCollector/logs/collector.log &

# Run Sumo's entrypoint
exec /run.sh "${@}"
