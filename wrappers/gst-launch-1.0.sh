#!/bin/bash

export GST_DEBUG=1 #1: ERROR (Log fatal errors only).
export LD_LIBRARY_PATH=/var/packages/@package_name@/target/lib/gstreamer/patch
export GST_PLUGIN_PATH=/var/packages/@package_name@/target/lib/gstreamer/gstreamer-1.0/patch

#########################
# VARS
#########################

pid=$$
stderrfile="/tmp/gstlaunch-$pid.stderr"
errcode=0

#########################
# UTILS
#########################

log() {
  local now
  now=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$now] [$1] $2" >> "$stderrfile"
}

newline() {
  echo "" >> "$stderrfile"
}

info() {
  log "INFO" "$1"
}

kill_child() {
  if [[ "$child" != "" ]]; then
    kill "$child" > /dev/null 2> /dev/null || :
  fi
}

endprocess() {
  info "========================================[end $0 $pid]"
  newline

  if [[ $errcode -eq 1 ]]; then
    cp "$stderrfile" "$stderrfile.prev"
  fi

  kill_child
  rm -f "$stderrfile"

  exit "$errcode"
}

handle_error() {
  log "ERROR" "An error occurred"
  newline
  errcode=1
  kill_child
}

#########################
# ENTRYPOINT
#########################

trap endprocess SIGINT SIGTERM
trap handle_error ERR

rm -f /tmp/gstlaunch*.stderr.prev

newline
info "========================================[start $0 $pid]"
info "GST_ARGS: $*"

# Get the original pipeline to modify
original_pipeline="$*"

# Force 5.1 audio output
gst-launch-1.0 -v $original_pipeline ! audioconvert ! audioresample ! "audio/x-raw,channels=6,layout=interleaved" ! alsasink 2>> $stderrfile &

child=$!
wait "$child"

endprocess
