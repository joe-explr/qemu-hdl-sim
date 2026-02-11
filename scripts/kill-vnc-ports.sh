#!/bin/bash
set -euo pipefail

ports=(5908 5909)

find_pids() {
  local port="$1"

  if command -v lsof >/dev/null 2>&1; then
    lsof -tiTCP:"${port}" -sTCP:LISTEN 2>/dev/null
    return 0
  fi

  if command -v fuser >/dev/null 2>&1; then
    fuser -n tcp "${port}" 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+$/) print $i}'
    return 0
  fi

  if command -v ss >/dev/null 2>&1; then
    ss -lptn "sport = :${port}" 2>/dev/null | awk '{
      while (match($0, /pid=[0-9]+/)) {
        print substr($0, RSTART + 4, RLENGTH - 4)
        $0 = substr($0, RSTART + RLENGTH)
      }
    }' | sort -u
    return 0
  fi
}

had_any=false

for port in "${ports[@]}"; do
  mapfile -t pids < <(find_pids "${port}")

  if (( ${#pids[@]} == 0 )); then
    echo "No process listening on port ${port}"
    continue
  fi

  echo "Killing port ${port}: ${pids[*]}"
  kill "${pids[@]}"
  had_any=true

done

if [[ "${had_any}" == false ]]; then
  echo "Nothing to kill."
fi
