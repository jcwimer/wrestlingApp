# WrestlingDev load-test performance evaluation

Use this prompt after a local end-to-end load test. Paste it into an agent session with the repo available and the test stack still running.

## What was run

**Load test command:**

```sh
sudo rm -rf loadtests/results/*; docker compose -f deploy/docker-compose-test.yml down; docker volume rm $(docker volume ls -q); bash deploy/deploy-test.sh; cd loadtests; docker compose build; BASE_URL=http://host.docker.internal TEST_DURATION_SECONDS=900 TOURNAMENT_COUNT=4 docker compose run --rm gatling; cd ..;
```

**Stack still running** (do not tear down until analysis is done):

```sh
docker-compose -f deploy/docker-compose-test.yml ps
```

Telemetry stack from `deploy/docker-compose-test.yml` should still be up: app, MariaDB, otel-collector, Jaeger, Prometheus, Grafana, node-exporter, cAdvisor, mariadb-exporter.

## Load profile (four tournaments, `TOURNAMENT_COUNT=4`)

This simulates **four tournaments** at roughly peak-day traffic using seeded load-test tournaments `205`–`208`. From `loadtests/README.md` and `TournamentLoadSimulation.java`:

Per tournament:

- 5 Playwright mat operators (real browser JS: clock, scoring events, submit ~1/min, staggered by mat within each tournament)
- 1 Playwright `live_scores` observer (browser DOM/delivery metrics)
- 3 anonymous full-screen `up_matches` Turbo Stream viewers
- 3 req/s anonymous spectators (30% up_matches, 10% team scores, 30% bracket, 10% school, 10% weight, 10% tournament page)
- 20 persistent `live_scores` Action Cable viewers (ramped over 30s), with periodic `request_sync` WS round-trips

Total across four tournaments:

- 20 Playwright mat operators
- 4 Playwright `live_scores` observers
- 12 anonymous full-screen `up_matches` viewers
- 12 req/s anonymous spectators
- 80 persistent `live_scores` Action Cable viewers
- 15-minute measured duration (`TEST_DURATION_SECONDS=900`)
- Gatling assertions: zero failed HTTP requests; WS sync p95 < 1000ms

Per-tournament defaults come from the `PER_TOURNAMENT_*` environment variables in `loadtests/docker-compose.yml`.

**Note:** `PER_TOURNAMENT_LIVE_SCORE_VIEWERS` defaults to 20 per tournament (80 total with `TOURNAMENT_COUNT=4`) in `loadtests/docker-compose.yml`, `loadtests/run.sh`, and `TournamentLoadSimulation.java`. Live scores are a newer feature; 20 viewers per tournament is the current planning baseline until real-world load is better understood. Confirm the actual viewer count from the Gatling report or container env.

## Environment context

### Local test host (this run)

- WSL2 on Windows
- CPU: AMD Ryzen 9 7940HS (all cores allocated to WSL)
- RAM: 12GB allocated to WSL
- Storage: NVMe (disk I/O should not be the bottleneck)
- Docker Compose test stack (`deploy/docker-compose-test.yml`):
  - `WEB_CONCURRENCY=2`, `RAILS_MAX_THREADS=5`, `RAILS_MIN_THREADS=5`
  - `SOLID_QUEUE_IN_PUMA=true`
  - MariaDB 10.10 with default settings (no prod `70-mysettings.cnf`)
  - Single app container behind ports 80/443

### Production host (extrapolation target)

- CPU: Intel Core i7-8700 @ 3.20GHz (6c/12t)
- RAM: 64GB
- Storage: NVMe
- Docker Compose prod stack (`deploy/docker-compose-prod.yml`):
  - `WEB_CONCURRENCY=4`, `RAILS_MAX_THREADS=5`, `RAILS_MIN_THREADS=5`
  - `SOLID_QUEUE_IN_PUMA=true`, Solid Queue workers: 3 threads × `JOB_CONCURRENCY` (default 1) in `config/queue.yml`
  - MariaDB 10.10 with prod tuning in `deploy/mariadb/70-mysettings-master.cnf` (slow query log, buffer settings, etc.)
  - Traefik/nginx in front (not present in local test stack)

When extrapolating local → prod, account for: **2× Puma workers locally vs 4× in prod**, different CPU architecture/clock, **12GB vs 64GB RAM**, missing reverse-proxy hop locally, and prod MariaDB tuning. Do not treat local absolute throughput as a 1:1 prod number; use **resource headroom ratios** and **latency/error margins**.

## Artifacts to read (in repo)

### Gatling / Playwright

- `loadtests/results/` — open the HTML report (`index.html` or latest simulation folder)
- `loadtests/results/simulation.log`
- `loadtests/results/live-score-browser-metrics.json` — browser delivery/DOM p95 thresholds: delivery 1000ms, DOM paint 250ms

Extract and summarize:

- Global request stats (count, OK/KO, mean/p50/p95/p99/max)
- Per-scenario stats (spectators, live score WS, preparation, mat ops if present)
- WS sync round-trip latency distribution
- Any assertion failures or KO requests
- Browser metrics vs `BROWSER_DELIVERY_MAX_P95_MS` / `BROWSER_DOM_MAX_P95_MS`

### Application logs

```sh
docker-compose -f deploy/docker-compose-test.yml logs app --since 30m
docker-compose -f deploy/docker-compose-test.yml logs db --since 30m
```

Look for: 5xx, timeouts, ActiveRecord pool checkout timeouts, Solid Queue errors, Action Cable errors, slow request warnings, MariaDB connection errors (`Too many connections`). A growing Solid Queue backlog by itself is not a user-visible failure (see **Background jobs** below).

### OpenTelemetry traces (Jaeger)

- UI: http://localhost:16686
- Service: `wrestlingdev`
- Time range: full 15-minute load window (+ prep if visible)

Find:

- Slowest HTTP routes and Action Cable operations (p95/p99 span duration)
- Hot `ActiveRecord` / SQL spans (`rails-otel-slowlog-by-sql`, `rails-otel-slowlog-by-action` dashboards mirror this)
- Solid Queue job latency and error spans (filter queue polling noise — otel collector already drops fast SolidQueue poll spans <100ms). Report job timings for context, but weight them lower than user-visible metrics (see **Background jobs**).
- Error traces and retry patterns
- Whether latency is app-bound, DB-bound, or queue-bound (for **request/WS paths**; job backlog is secondary)

### Prometheus metrics

- UI: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin, anonymous admin enabled locally)

Use dashboards in `deploy/grafana/dashboards/`:

- **Rails OTEL Overview** (`rails-otel-overview`)
- **Rails OTEL Performance** / **Per Request** / **Per Action**
- **Rails OTEL Requests**, **ActiveJob**, **Action Cable**
- **MariaDB / Exporter** (`mariadb-exporter`) — especially connection utilization
- **Node Exporter** — CPU, memory, load, disk (sanity check WSL saturation)

### Load-generator resource attribution (required for local runs)

Gatling and its Playwright browsers run in a Docker container on the same local WSL host as the test stack. They consume meaningful CPU and RAM, so node-exporter host utilization is **not** application-server utilization and must not be used as a direct production capacity limit.

Use cAdvisor (`job="cadvisor"`) to report the Gatling container's peak and sustained CPU and memory separately, then distinguish its share from the app, MariaDB, and telemetry containers. The local host's total CPU/memory remains useful as a saturation check, but capacity extrapolation should account for the fact that production will not run the load generator. Do not simply subtract a single peak sample or multiply capacity by the apparent remaining CPU; container contention, CPU architecture, Puma worker count, and real-event burstiness still matter.

Key Prometheus queries to evaluate:

```promql
# MariaDB connection headroom
mysql_global_status_threads_connected{job="mariadb"}
mysql_global_variables_max_connections{job="mariadb"}
100 * mysql_global_status_threads_connected / mysql_global_variables_max_connections

# Request latency from span metrics (otel-collector job)
histogram_quantile(0.95, sum(rate(traces_span_metrics_duration_milliseconds_bucket{service_name="wrestlingdev"}[5m])) by (le, http_route))
histogram_quantile(0.99, sum(rate(traces_span_metrics_duration_milliseconds_bucket{service_name="wrestlingdev"}[5m])) by (le, http_route))

# Error rate
sum(rate(traces_span_metrics_calls_total{service_name="wrestlingdev", status_code="STATUS_CODE_ERROR"}[5m]))

# Gatling container CPU cores and working-set memory
sum by (name) (rate(container_cpu_usage_seconds_total{job="cadvisor", name=~".*gatling.*"}[5m]))
sum by (name) (container_memory_working_set_bytes{job="cadvisor", name=~".*gatling.*"})
```

Report peak and sustained values during the 900s window, not just end-state.

## MariaDB connection budget (required)

**Exhausting MariaDB connections is unacceptable.** Build an explicit connection budget.

1. Read `max_connections` and peak `Threads_connected` during the test (Prometheus/Grafana + optional `SHOW GLOBAL STATUS LIKE 'Threads_connected'` / `SHOW VARIABLES LIKE 'max_connections'` via `docker-compose exec db`).

2. Calculate **maximum theoretical app demand** from config:
   - Puma: `WEB_CONCURRENCY` workers × `RAILS_MAX_THREADS` threads
   - Active Record: production uses 4 MariaDB databases (`primary`, `queue`, `cache`, `cable` in `config/database.yml`)
   - Pool size: `DATABASE_POOL_SIZE` if set, else `max(RAILS_MAX_THREADS * WEB_CONCURRENCY, 5)` per the sqlite default template logic — verify what production actually uses when pool is omitted on MariaDB configs
   - Solid Queue in Puma: +3 worker threads on `queue` DB (`config/queue.yml`)
   - Reserve headroom for: mariadb-exporter, admin consoles, backups, replication

3. For **local test** and **prod** separately, show:

   | Consumer | Max connections |
   |----------|-----------------|
   | Rails primary pool | … |
   | Rails queue pool | … |
   | Rails cache pool | … |
   | Rails cable pool | … |
   | Solid Queue | … |
   | Other (exporter, etc.) | … |
   | **Total theoretical max** | … |
   | **Observed peak** | … |
   | **max_connections** | … |
   | **Headroom at peak** | … |

4. State whether the test approached connection exhaustion (>70% sustained, >85% peak, or any `Too many connections`). If pools are oversized relative to threads, say so.

## Background jobs (Solid Queue)

Tournament background work (`AdvanceWrestlerJob`, `CalculateTournamentTeamScoresJob`, `FillBoutBoardJob`, `SolidCable::TrimJob`, etc.) provides **eventual consistency** for brackets, team scores, bout boards, and related derived state. It does **not** drive mat-operator or live-score **perceived** performance — those paths are synchronous HTTP, Turbo Streams, and Action Cable.

When assessing backend health:

- **Prioritize** spectator HTTP latency, WS sync, mat-operator → live-score delivery/DOM paint, Action Cable stability, and MariaDB connection headroom.
- **Deprioritize** job duration and modest queue depth unless jobs are **failing**, retrying, or backlog growth correlates with user-visible degradation.
- Jobs are **intentionally not fully parallelized per tournament**; do not treat single-tournament job serialization as a bottleneck or recommend parallelizing them without strong evidence.

Still note job errors and extreme outliers, but do not let healthy job latency numbers drive a fail/marginal verdict when user-facing metrics pass.

## Performance assessment (required sections)

### 1. Executive summary

- Pass / marginal / fail for running **four tournaments at this load profile**
- Top 3 bottlenecks with evidence (metric + source)
- Single biggest risk for production

### 2. User-visible latency

- Spectator HTTP p95/p99
- Live score WS sync p95/p99 (Gatling)
- Mat operator → live score delivery and DOM paint (Playwright JSON)
- Compare against Gatling/browser thresholds

### 3. Backend health

- CPU/memory saturation on app host and DB (node-exporter), plus Gatling/Playwright CPU and memory from cAdvisor for local runs
- MariaDB: slow queries, buffer pool reads, threads running, lock waits
- Solid Queue: failures and retries first; backlog/job duration only if extreme or paired with user-visible issues (see **Background jobs**)
- Action Cable: connect/subscribe/broadcast latency

### 4. Errors and stability

- Failed requests, exceptions in logs, error spans
- Any degradation over the 15-minute window (warmup vs steady state vs end)

### 5. Local vs prod extrapolation

- Normalize results by **per-worker capacity** and **observed resource utilization**, not raw RPS alone. For a local run, separate cAdvisor-measured Gatling/Playwright consumption from host utilization; do not attribute generator CPU or RAM to the application.
- Call out what prod gains (4 workers, 64GB RAM, tuned MariaDB) vs loses (older CPU, Traefik hop, real-world variance)
- Give **low / expected / high** simultaneous tournament estimates

## Capacity recommendation (main deliverable)

**How many tournaments can run simultaneously at this load profile per tournament**, on **production**, without exhausting MariaDB connections and without unacceptable latency?

Define tiers:

| Tier | Criteria |
|------|----------|
| **Conservative (recommend for live events)** | p99 HTTP < 2s, WS sync p95 < 500ms, MariaDB connections < 60% of max, CPU < 70%, zero connection errors |
| **Expected** | p99 HTTP < 3s, WS sync p95 < 1000ms, MariaDB connections < 75%, CPU < 85% |
| **Aggressive (not recommended)** | At threshold of test assertions |

For each tier provide:

- **Estimated simultaneous tournaments** (integer range, e.g. 2–3)
- **Binding constraint** (MariaDB connections, CPU, Puma threads, Action Cable, Solid Queue, etc.)
- **MariaDB connection math** at that tournament count (remember: one app container — connections do not multiply per tournament, but **query load and thread contention do**)
- **What breaks first** if we exceed the estimate

If local test data is insufficient for a confident prod number, say what additional evidence you need (e.g. prod-like `WEB_CONCURRENCY=4` locally, a shorter test on prod, or a day with more live-score adoption than the 80-viewer baseline from this four-tournament run).

## Scaling on a single production server (before horizontal)

The goal is to **maximize the current production host** before adding app instances. When the capacity estimate is exceeded — or when **more simultaneous peak-day tournaments are scheduled on the same server than the recommended tier** — include a **Puma tuning** subsection with concrete suggestions tied to observed bottlenecks:

- **`WEB_CONCURRENCY` (workers):** Increase when CPU has headroom and latency is thread-queue-bound. Each worker adds up to `RAILS_MAX_THREADS` concurrent request capacity and multiplies per-database connection pools (4 MariaDB pools × pool size × workers). Re-check the MariaDB connection budget before raising workers.
- **`RAILS_MAX_THREADS` / `RAILS_MIN_THREADS`:** Increase only when workers are CPU-saturated but individual requests are I/O-bound (DB, cable, render wait). Raising threads without raising `DATABASE_POOL_SIZE` (or the implicit pool default) causes pool checkout timeouts. Prefer modest thread increases over large jumps.
- **`DATABASE_POOL_SIZE`:** If increasing threads or workers, pool must be ≥ threads per worker **per database** (primary, queue, cache, cable). Flag total theoretical connections against `max_connections` and observed peak.
- **`JOB_CONCURRENCY` / Solid Queue threads (`config/queue.yml`):** Secondary to Puma for user-visible load. Only suggest increases for job **failures** or runaway backlog that affects correctness — not for routine `AdvanceWrestlerJob` latency on a single tournament.
- **Order of operations:** (1) confirm user-visible metrics and connections at risk, (2) add workers if CPU allows, (3) add threads if still queue-bound, (4) adjust pools to match, (5) re-run load test or monitor the next live event.

State explicitly when the binding constraint is **not** fixable on one box (e.g. sustained CPU > 85% at recommended tournament count even after worker tuning) and horizontal scaling becomes appropriate.

## Remediation (prioritized)

Short, actionable list (max 5 items): config changes, indexing, pool sizing, Puma tuning, caching — each tied to evidence from traces/metrics/logs. Flag anything that risks **increasing** MariaDB connection usage. Deprioritize queue-parallelism changes unless jobs are failing. Include Puma worker/thread recommendations when scheduled tournament count exceeds the capacity tier.

## Cleanup reminder

After analysis:

```sh
docker-compose -f deploy/docker-compose-test.yml down
docker volume rm $(docker volume ls -q)
```

## Optional run specifics (fill in when pasting)

```markdown
**Run specifics:**
- Test started: [time/date]
- Gatling passed/failed: [ ]
- `TOURNAMENT_COUNT`: 4
- Live score WS viewers actually used: [ ] (total = `PER_TOURNAMENT_LIVE_SCORE_VIEWERS` × 4, default 80)
- Any env overrides: [ ]
- Notable anomalies during run: [ ]
```

## Quick reference

| Item | Local test | Production |
|------|------------|------------|
| Tournaments simulated | 4 | n/a |
| Puma workers | 2 | 4 |
| Threads/worker | 5 | 5 |
| Max concurrent request threads | 10 | 20 |
| MariaDB | default | tuned + slow log |
| Grafana | :3000 | Traefik host |
| Jaeger | :16686 | Traefik host |
| Results path | `loadtests/results/` | same |
