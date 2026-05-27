#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RESULTS_DIR="${RESULTS_DIR:-$SCRIPT_DIR/results}"

ROBOT_FILES=(
    epc_session_management.robot
    epc_transfer_control.robot
    channel_management.robot
    epc_readings_units_limits.robot
)

exit_code=0

for robot_file in "${ROBOT_FILES[@]}"; do
    if [[ ! -f "$robot_file" ]]; then
        echo "ERROR: missing test file: $robot_file" >&2
        exit_code=1
        continue
    fi

    suite_name="${robot_file%.robot}"
    dest="$RESULTS_DIR/$suite_name"
    mkdir -p "$dest"

    echo "==> Running $robot_file (output -> $dest/)"
    if ! robot --outputdir "$dest" "$robot_file"; then
        exit_code=1
    fi
    echo
done

exit "$exit_code"
