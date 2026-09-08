#!/bin/sh
set -eu

prepared_marker=/loadtests/run-state/prepared
rm -f "$prepared_marker"

node ./browser-operators.js &
operator_pid=$!

cleanup() {
  kill "$operator_pid" 2>/dev/null || true
  wait "$operator_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

set +e
mvn -B gatling:test \
  -Dgatling.simulationClass=com.wrestlingdev.TournamentLoadSimulation \
  -DbaseUrl="${BASE_URL:-http://host.docker.internal:3000}" \
  -DwsUrl="${WS_URL:-}" \
  -DtournamentId="${TOURNAMENT_ID:-204}" \
  -DtestDurationSeconds="${TEST_DURATION_SECONDS:-600}" \
  -DspectatorRequestsPerSecond="${SPECTATOR_REQUESTS_PER_SECOND:-3}" \
  -DliveScoreViewers="${LIVE_SCORE_VIEWERS:-100}" \
  -DviewerRampSeconds="${VIEWER_RAMP_SECONDS:-30}" \
  -DwsProbeIntervalSeconds="${WS_PROBE_INTERVAL_SECONDS:-10}" \
  -DwsResponseTimeoutSeconds="${WS_RESPONSE_TIMEOUT_SECONDS:-10}" \
  -DwsMaxP95Ms="${WS_MAX_P95_MS:-1000}" \
  -DwsUnmatchedBufferSize="${WS_UNMATCHED_BUFFER_SIZE:-1000}" \
  -DoperatorMatchSeconds="${OPERATOR_MATCH_SECONDS:-50}" \
  -DoperatorEmail="${OPERATOR_EMAIL:-test@test.com}" \
  -DoperatorPassword="${OPERATOR_PASSWORD:-password}" \
  -DgenerationTimeoutSeconds="${GENERATION_TIMEOUT_SECONDS:-600}"
gatling_status=$?
set -e

if [ "$gatling_status" -eq 0 ]; then
  wait "$operator_pid"
else
  exit "$gatling_status"
fi
