# Tournament load tests

This Dockerized Gatling suite prepares seeded load-test tournaments, then runs the load for 10 minutes by default.

The browser operators use Playwright 1.63.0. Keep the version in `package.json` and `package-lock.json` matched to the Playwright image in `Dockerfile`; Docker installs the locked dependencies with `npm ci`.

Seeds create `Load Test Tournament 1` through `Load Test Tournament 10` (IDs `205`-`214`) with the same layout as seeded tournament `204`, including five mats named `Load Test 1` through `Load Test 5` on each tournament.

The preparation user logs in as `test@test.com`, regenerates matches for each active load-test tournament, and polls the first mat state page until a newly generated match is available. The measured load starts only after preparation succeeds.

Set `TOURNAMENT_COUNT` from `1` to `10` to run that many load-test tournaments at once. Each tournament receives the same per-tournament load profile described below.

The measured workload per tournament contains:

- five authenticated Chromium mat operators, one per load-test mat; Playwright loads the real state page, runs its Stimulus controllers, waits 10 seconds before starting the clock, records a scoring event every 10 seconds until the simulated bout ends, and submits the JavaScript-derived result approximately once per minute. Operator starts and match durations are offset so completions do not occur in artificial lockstep;
- one real Chromium `live_scores` observer by default, which follows the application's Stimulus subscription behavior and records message-handler, frame-to-paint, and mat-operator-action-to-DOM-paint latency in `results/live-score-browser-metrics.json`;
- three anonymous full-screen `up_matches` viewers with persistent Turbo Stream subscriptions;
- anonymous spectators arriving at 3 requests/second, split 30% `up_matches`, 10% team scores, 30% random bracket, 10% random school, 10% random weight, and 10% tournament page;
- 20 anonymous `live_scores` protocol viewers, ramped in over 30 seconds, with persistent mat and match Action Cable subscriptions. They verify subscription confirmations, follow mat queue changes by replacing match subscriptions, and periodically measure a `request_sync` websocket round trip.

Run it from this directory while the application and its job worker are available:

```sh
docker compose build
docker compose run --rm gatling
```

Gatling drives preparation and all spectator traffic. The same container starts five headless Playwright browser contexts per active tournament for mat operation because Gatling itself does not execute browser JavaScript. A preparation marker prevents those browsers from opening the state pages until match generation has finished.

For a local Rails server, bind Rails to an address Docker can reach, for example `bin/rails server -b 0.0.0.0`. Do not set `BASE_URL` to `127.0.0.1`, which means the Gatling container itself; use the default `http://host.docker.internal:3000`. Reports are written to `loadtests/results/`.

Gatling websocket timings include the Action Cable welcome, subscription confirmations, replacement-match confirmations, and periodic sync round trips. Unsolicited mat messages are buffered and drained between probes, then coalesced to the latest topology before changing subscriptions. A replacement is only tracked after the server confirms its subscription, keeping sync measurements attached to matches the client can actually reach. This matches the `live_scores` controller behavior. Gatling does not execute page JavaScript, so the separate Playwright observer correlates each operator scoring action with its matching score broadcast and supplies both delivery and browser-side DOM metrics.

Configuration is supplied through environment variables. Per-tournament settings apply independently to each active load-test tournament; overall settings apply once to the entire run.

| Variable | Default | Scope | Purpose |
| --- | --- | --- | --- |
| `BASE_URL` | `http://host.docker.internal:3000` | overall | Rails HTTP(S) origin, without a trailing slash |
| `WS_URL` | derived from `BASE_URL` | overall | Optional Action Cable WS(S) origin |
| `TOURNAMENT_COUNT` | `1` | overall | Number of load-test tournaments to exercise (`1`-`10`, uses tournaments `205` through `205 + count - 1`) |
| `TEST_DURATION_SECONDS` | `600` | overall | Measured workload duration |
| `GENERATION_TIMEOUT_SECONDS` | `600` | overall | Maximum wait for match generation |
| `OPERATOR_EMAIL` | `test@test.com` | overall | Mat operator/preparation login |
| `OPERATOR_PASSWORD` | `password` | overall | Seeded login password |
| `OPERATOR_STAGGER_SECONDS` | `7` | per tournament | Delay between the initial start of each mat operator within a tournament |
| `BROWSER_ACTION_TIMEOUT_SECONDS` | `120` | overall | Playwright action and navigation timeout under load |
| `WS_RESPONSE_TIMEOUT_SECONDS` | `10` | overall | Maximum wait for websocket welcome, confirmation, and sync frames |
| `WS_MAX_P95_MS` | `1000` | overall | Gatling assertion threshold for websocket sync round-trip p95 |
| `WS_UNMATCHED_BUFFER_SIZE` | `1000` | overall | Per-viewer buffer for unsolicited websocket frames used to follow mat changes |
| `BROWSER_DOM_MAX_P95_MS` | `250` | overall | Failure threshold for real-browser websocket-to-DOM-paint p95 |
| `BROWSER_DELIVERY_MAX_P95_MS` | `1000` | overall | Failure threshold for mat-operator-action-to-live-score-DOM-paint p95 |
| `PER_TOURNAMENT_SPECTATOR_REQUESTS_PER_SECOND` | `3` | per tournament | Anonymous spectator arrival rate |
| `PER_TOURNAMENT_LIVE_SCORE_VIEWERS` | `20` | per tournament | Persistent live-score viewers |
| `PER_TOURNAMENT_LIVE_SCORE_BROWSER_VIEWERS` | `1` | per tournament | Real Chromium live-score observers used to measure client DOM handling |
| `PER_TOURNAMENT_VIEWER_RAMP_SECONDS` | `30` | per tournament | Time over which persistent websocket viewers connect |
| `PER_TOURNAMENT_WS_PROBE_INTERVAL_SECONDS` | `10` | per tournament | Interval between websocket `request_sync` round-trip probes per viewer |
| `PER_TOURNAMENT_OPERATOR_MATCH_SECONDS` | `50` | per tournament | Simulated time spent running each bout before submission |
| `PER_TOURNAMENT_OPERATOR_CLOCK_START_DELAY_SECONDS` | `10` | per tournament | Delay before starting the match clock |
| `PER_TOURNAMENT_OPERATOR_EVENT_INTERVAL_SECONDS` | `10` | per tournament | Interval between scoring events during a bout |
| `PER_TOURNAMENT_OPERATOR_MATCH_JITTER_SECONDS` | `10` | per tournament | Maximum random variation above or below each simulated bout duration |

For example:

```sh
BASE_URL=https://test.example.com TOURNAMENT_COUNT=3 TEST_DURATION_SECONDS=900 docker compose run --rm gatling
```

Preparation regenerates all matches for each active load-test tournament, matching the application's existing Generate Brackets behavior. Run this against an environment where replacing those tournament matches is safe.

## Run full end to end tests preserving otel traces, prometheus metrics, and application logs for analysis:
```sh
docker compose -f deploy/docker compose-test.yml down; docker volume rm $(docker volume ls -q); bash deploy/deploy-test.sh; sudo rm -rf loadtests/results/*; cd loadtests; docker compose build; BASE_URL=http://host.docker.internal TOURNAMENT_COUNT=1 TEST_DURATION_SECONDS=900 docker compose run --rm gatling; cd ..;
```

When finished with analysis:
```sh
docker compose -f deploy/docker compose-test.yml down; docker volume rm $(docker volume ls -q);
```

For post-run analysis, use the agent prompt in [`agent_prompts/LOAD_TEST_EVALUATION.md`](../agent_prompts/LOAD_TEST_EVALUATION.md).
