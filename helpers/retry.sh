#!/bin/bash

# retry.sh - retry a command with exponential backoff
#
# Usage:
#   source retry.sh
#   retry 4 docker push ghcr.io/ctu-mrs/buildfarm2:image_name
#
# Arguments:
#   $1       - max number of attempts
#   $2...$N  - command to execute

retry() {
  local max_attempts=$1
  shift
  local attempt=1
  local delay=1
  local exit_code=0

  while true; do
    "$@" && return 0
    exit_code=$?

    if (( attempt >= max_attempts )); then
      echo "retry: '$*' failed after $max_attempts attempts" >&2
      return "$exit_code"
    fi

    echo "retry: '$*' failed (attempt $attempt/$max_attempts), retrying in ${delay}s..." >&2
    sleep "$delay"
    (( attempt++ ))
    (( delay *= 2 ))
  done
}
