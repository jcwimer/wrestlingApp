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
mvn -B -o gatling:test \
  -Dgatling.simulationClass=com.wrestlingdev.TournamentLoadSimulation \
  -DbaseUrl="${BASE_URL:-http://host.docker.internal:3000}" \
  -DwsUrl="${WS_URL:-}" \
  -DtournamentCount="${TOURNAMENT_COUNT:-1}" \
  -DtestDurationSeconds="${TEST_DURATION_SECONDS:-600}" \
  -DperTournamentSpectatorRequestsPerSecond="${PER_TOURNAMENT_SPECTATOR_REQUESTS_PER_SECOND:-3}" \
  -DperTournamentLiveScoreViewers="${PER_TOURNAMENT_LIVE_SCORE_VIEWERS:-20}" \
  -DperTournamentViewerRampSeconds="${PER_TOURNAMENT_VIEWER_RAMP_SECONDS:-30}" \
  -DperTournamentWsProbeIntervalSeconds="${PER_TOURNAMENT_WS_PROBE_INTERVAL_SECONDS:-10}" \
  -DwsResponseTimeoutSeconds="${WS_RESPONSE_TIMEOUT_SECONDS:-10}" \
  -DwsMaxP95Ms="${WS_MAX_P95_MS:-1000}" \
  -DwsUnmatchedBufferSize="${WS_UNMATCHED_BUFFER_SIZE:-1000}" \
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
