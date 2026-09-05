# Tournament load tests

This Dockerized Gatling suite prepares seeded tournament `204`, then runs the load for 10 minutes by default.

The browser operators use Playwright 1.63.0. Keep the version in `package.json` and `package-lock.json` matched to the Playwright image in `Dockerfile`; Docker installs the locked dependencies with `npm ci`.

The preparation user logs in as `test@test.com`, idempotently creates five mats named `Load Test 1` through `Load Test 5`, regenerates the tournament matches, and polls the mat state page until a newly generated match is available. The measured load starts only after preparation succeeds.

The measured workload contains:

- five authenticated Chromium mat operators, one per load-test mat; Playwright loads the real state page, runs its Stimulus controllers, starts/stops the clock, records a takedown, and submits the JavaScript-derived result approximately once per minute. Operator starts and match durations are offset so completions do not occur in artificial lockstep;
- one real Chromium `live_scores` observer by default, which follows the application's Stimulus subscription behavior and records message-handler, frame-to-paint, and mat-operator-action-to-DOM-paint latency in `results/live-score-browser-metrics.json`;
- three anonymous full-screen `up_matches` viewers with persistent Turbo Stream subscriptions;
- anonymous spectators arriving at 3 requests/second, split 30% `up_matches`, 10% team scores, 30% random bracket, 10% random school, 10% random weight, and 10% tournament page;
- 100 anonymous `live_scores` protocol viewers, ramped in over 30 seconds, with persistent mat and match Action Cable subscriptions. They verify subscription confirmations, follow mat queue changes by replacing match subscriptions, and periodically measure a `request_sync` websocket round trip.

Run it from this directory while the application and its job worker are available:

```sh
docker-compose build
docker-compose run --rm gatling
```

Gatling drives preparation and all spectator traffic. The same container starts five headless Playwright browser contexts for mat operation because Gatling itself does not execute browser JavaScript. A preparation marker prevents those browsers from opening the state pages until match generation has finished.

For a local Rails server, bind Rails to an address Docker can reach, for example `bin/rails server -b 0.0.0.0`. Do not set `BASE_URL` to `127.0.0.1`, which means the Gatling container itself; use the default `http://host.docker.internal:3000`. Reports are written to `loadtests/results/`.

Gatling websocket timings include the Action Cable welcome, subscription confirmations, replacement-match confirmations, and periodic sync round trips. Unsolicited mat messages are buffered and drained between probes, then coalesced to the latest topology before changing subscriptions. A replacement is only tracked after the server confirms its subscription, keeping sync measurements attached to matches the client can actually reach. This matches the `live_scores` controller behavior. Gatling does not execute page JavaScript, so the separate Playwright observer correlates each operator takedown with its matching score broadcast and supplies both delivery and browser-side DOM metrics.

Configuration is supplied through environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `BASE_URL` | `http://host.docker.internal:3000` | Rails HTTP(S) origin, without a trailing slash |
| `WS_URL` | derived from `BASE_URL` | Optional Action Cable WS(S) origin |
| `TOURNAMENT_ID` | `204` | Seeded tournament to exercise |
| `TEST_DURATION_SECONDS` | `600` | Measured workload duration |
| `SPECTATOR_REQUESTS_PER_SECOND` | `3` | Anonymous spectator arrival rate |
| `LIVE_SCORE_VIEWERS` | `100` | Persistent live-score viewers |
| `LIVE_SCORE_BROWSER_VIEWERS` | `1` | Real Chromium live-score observers used to measure client DOM handling |
| `VIEWER_RAMP_SECONDS` | `30` | Time over which persistent websocket viewers connect |
| `WS_PROBE_INTERVAL_SECONDS` | `10` | Interval between websocket `request_sync` round-trip probes per viewer |
| `WS_RESPONSE_TIMEOUT_SECONDS` | `10` | Maximum wait for websocket welcome, confirmation, and sync frames |
| `WS_MAX_P95_MS` | `1000` | Gatling assertion threshold for websocket sync round-trip p95 |
| `WS_UNMATCHED_BUFFER_SIZE` | `1000` | Per-viewer buffer for unsolicited websocket frames used to follow mat changes |
| `OPERATOR_MATCH_SECONDS` | `50` | Simulated time spent running each bout before submission |
| `OPERATOR_STAGGER_SECONDS` | `7` | Delay between the initial start of each mat operator |
| `OPERATOR_MATCH_JITTER_SECONDS` | `10` | Maximum random variation above or below each simulated bout duration |
| `BROWSER_DOM_MAX_P95_MS` | `250` | Failure threshold for real-browser websocket-to-DOM-paint p95 |
| `BROWSER_DELIVERY_MAX_P95_MS` | `1000` | Failure threshold for mat-operator-action-to-live-score-DOM-paint p95 |
| `OPERATOR_EMAIL` | `test@test.com` | Mat operator/preparation login |
| `OPERATOR_PASSWORD` | `password` | Seeded login password |
| `GENERATION_TIMEOUT_SECONDS` | `600` | Maximum wait for match generation |

For example:

```sh
BASE_URL=https://test.example.com TEST_DURATION_SECONDS=900 docker-compose run --rm gatling
```

Preparation is intentionally non-destructive to unrelated mats. Repeated runs reuse the five named load-test mats but regenerate all matches, matching the application's existing Generate Brackets behavior. Run this against an environment where replacing tournament `204` matches is safe.
