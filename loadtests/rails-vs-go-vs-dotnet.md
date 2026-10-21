# Rails vs Go vs .NET load test comparison

Recorded **2026-10-21** on the standard four-tournament, 15-minute profile (`TOURNAMENT_COUNT=4`, `TEST_DURATION_SECONDS=900`). Workload details and environment variables are in [README.md](README.md). For post-run analysis prompts, see [`agent_prompts/LOAD_TEST_EVALUATION.md`](../agent_prompts/LOAD_TEST_EVALUATION.md).

This document compares **Rails** (production baseline in `deploy/docker-compose-test.yml`), the **Go rewrite** (`go_rewrite/`, port **8081**, `LIVE_PROTOCOL=go`), and the **.NET rewrite** (`dotnet/`, port **8082**, `LIVE_PROTOCOL=rails` for Action Cable–compatible WebSockets). All three use the same Gatling suite and seeded MariaDB data from `deploy/deploy-test.sh`.

## How to reproduce

### Rails

```sh
bash deploy/deploy-test.sh
cd loadtests && docker compose build
BASE_URL=http://host.docker.internal TOURNAMENT_COUNT=4 TEST_DURATION_SECONDS=900 docker compose run --rm gatling
```

### Go

From the repo root, the supported path is `bash go_rewrite/local-loadtest.sh` (four tournaments, 15 minutes). For a manual run after `deploy-test.sh`:

```sh
docker build -t wrestlingdev-go:latest go_rewrite
bin/docker-compose -f go_rewrite/deploy/docker-compose-test.yml -p wrestlingdev-go run --rm app -install-support
bin/docker-compose -f go_rewrite/deploy/docker-compose-test.yml -p wrestlingdev-go up -d --force-recreate
bin/docker-compose -f deploy/docker-compose-test.yml stop app   # only the rewrite should serve HTTP
cd loadtests && docker compose build
LIVE_PROTOCOL=go BASE_URL=http://host.docker.internal:8081 TOURNAMENT_COUNT=4 TEST_DURATION_SECONDS=900 docker compose run --rm gatling
```

Use **`-p wrestlingdev-go`** (or an explicit Compose project `name`) so Go does not recreate `deploy-app-1`. `.NET` already sets `name: wrestlingdev-dotnet` in its compose file.

### .NET

```sh
bash dotnet/local-loadtest.sh
```

Or the same pattern as Go with `dotnet/deploy/docker-compose-test.yml`, port **8082**, and `LIVE_PROTOCOL=rails`.

### Metrics

- Gatling HTML and JSON under `loadtests/results/`
- cAdvisor/Prometheus from the test stack (`deploy/docker-compose-test.yml`); use a **5 minute** rate window for CPU (cAdvisor housekeeping is 55s)
- Sample `docker stats` during the run; attribute the Gatling container separately from the app and MariaDB

Archived numbers and orchestrator logs from the 2026-10-21 run: `tmp/loadtest-comparison/20261021T004311Z/` and `tmp/loadtest-comparison/20261021T004311Z/go-rerun/`.

---

## Executive summary

| Stack | Gatling | User-facing SLOs |
|-------|---------|------------------|
| **Rails** | Pass | HTTP, WS sync, and browser p95 thresholds met |
| **Go** | Pass (valid run with isolated Compose project) | Met; best HTTP tails and highest Gatling throughput in this run |
| **.NET** | Pass | Met; lowest HTTP p95/p99; one browser delivery max ~10s (p95 still 99ms) |

Go and .NET used much less **app** CPU and RAM than Rails. **MariaDB** peaked highest during the **.NET** run. The Gatling+Playwright container used ~0.9 CPU cores and ~2.5–2.7 GiB working set on every run—do not count that as application server load in capacity planning.

---

## Test configuration

| Parameter | Value |
|-----------|--------|
| Tournaments | 205–208 (`TOURNAMENT_COUNT=4`) |
| Measured duration | 900s after preparation |
| Host | WSL2, ~11.7 GiB RAM to Docker |
| MariaDB | 10.10, default test-stack tuning |
| Rails | `WEB_CONCURRENCY=2`, `RAILS_MAX_THREADS=5`, `SOLID_QUEUE_IN_PUMA=true` |

| Stack | `BASE_URL` | `LIVE_PROTOCOL` | Serving traffic |
|-------|------------|-----------------|-----------------|
| Rails | `http://host.docker.internal` (:80) | `rails` | `deploy` app container |
| Go | `http://host.docker.internal:8081` | `go` | `wrestlingdev-go` app; Rails app **stopped** |
| .NET | `http://host.docker.internal:8082` | `rails` | `wrestlingdev-dotnet` app; Rails app **stopped** |

### Go compose project pitfall

If `go_rewrite/deploy/docker-compose-test.yml` is started **without** a dedicated Compose project name, Docker Compose may treat it as the same project as `deploy/docker-compose-test.yml` and recreate **`deploy-app-1`** instead of listening on **8081**. A mistaken run produced 5,937 failed events (`Connection refused` on `:8081`). Valid Go results below used **`-p wrestlingdev-go`**.

---

## Gatling HTTP (global)

| Metric | Rails | Go | .NET |
|--------|------:|---:|-----:|
| Requests | 42,543 | 50,052 | 42,491 |
| Failed (KO) | 0 | 0 | 0 |
| Mean | 9 ms | 2 ms | 2 ms |
| p50 | 1 ms | 0 ms | 1 ms |
| **p95** | **38 ms** | 11 ms | **7 ms** |
| **p99** | **82 ms** | 13 ms | **9 ms** |
| Max | 1,608 ms | 177 ms | 572 ms |
| Mean throughput | 46.19 rps | **54.46 rps** | 46.19 rps |

All runs satisfied zero failed HTTP requests. Rails showed a small tail of slow responses (six between 800–1200 ms, one above 1200 ms). Rewrites had tighter tails in this environment.

**Report directories (2026-10-21):**

- Rails: `results/tournamentloadsimulation-20261021004723020/`
- .NET: `results/tournamentloadsimulation-20261021013243286/`
- Go: `results/tournamentloadsimulation-20261021015145047/`

---

## WebSocket sync (Gatling)

Assertion: per-tournament `receive websocket sync` p95 **&lt; 1000 ms**.

| Tournament | Rails p95 | Go p95 | .NET p95 |
|------------|----------:|-------:|---------:|
| 205 | 4 ms | 4 ms | 2 ms |
| 206 | 4 ms | 4 ms | 2 ms |
| 207 | 4 ms | 4 ms | 2 ms |
| 208 | 3 ms | 4 ms | 2 ms |

---

## Real browser (Playwright `live_scores`)

Thresholds: operator→DOM delivery p95 &lt; 1000 ms, WS→DOM paint p95 &lt; 250 ms.

| p95 | Rails | Go | .NET |
|-----|------:|---:|-----:|
| Message handler | 0.7 ms | 0.6 ms | 0.6 ms |
| WS → DOM paint | 14.4 ms | 14.5 ms | 14.5 ms |
| Operator → DOM paint | 119 ms | 103 ms | 99 ms |

| max (operator → DOM paint) | Rails | Go | .NET |
|----------------------------|------:|---:|-----:|
| | 151 ms | 106 ms | 9,989 ms |

Mat operators on successful runs: all submissions **303**, no operator failures in `browser-operator-metrics.json`.

---

## CPU and memory

### Application container

| | Rails | Go | .NET |
|--|------:|---:|-----:|
| `docker stats` peak CPU | 217% | 53% | 152% |
| `docker stats` avg CPU | 33% | 15% | 20% |
| `docker stats` peak RAM | 982 MiB | 38 MiB | 210 MiB |
| cAdvisor peak CPU (cores) | 0.38 | 0.16 | 0.21 |
| cAdvisor peak working set | 974 MiB | 37 MiB | 237 MiB |

Rails peak memory reflects two Puma workers, Ruby heap, and Solid Queue in Puma. Go’s container is a single static binary with a much smaller footprint.

### MariaDB (`deploy-db-1`)

| | Rails | Go | .NET |
|--|------:|---:|-----:|
| `docker stats` peak CPU | 38% | 41% | 85% |
| `docker stats` avg CPU | 10% | 12% | 15% |
| `docker stats` peak RAM | 200 MiB | 176 MiB | 243 MiB |
| cAdvisor peak working set | 194 MiB | (see stats) | 278 MiB |

**.NET** drove the highest MariaDB CPU and RAM in this comparison despite similar client-facing latency—worth a follow-up with slow query log and query volume vs Rails at comparable load.

### MariaDB connections (Prometheus, peak during run)

| Run | `Threads_connected` | `max_connections` |
|-----|----------------------:|------------------:|
| Rails | 44 | 151 (~29%) |
| .NET | 59 | 151 (~39%) |

No connection exhaustion at this profile.

### Load generator (Gatling + Playwright)

Peak ~495–530% CPU and ~2.1–2.6 GiB RAM (`docker stats`); ~0.87–0.90 cores and ~2.5–2.7 GiB working set (cAdvisor). Subtract from host totals when judging app headroom.

---

## Takeaways

1. **Parity:** All three passed the same Gatling assertions on valid infrastructure setups.
2. **Latency:** Rewrites improved HTTP percentiles; .NET had the tightest p95/p99 in this run.
3. **Efficiency:** Go and .NET used far less app memory and CPU than Rails; Go had the highest reported HTTP throughput.
4. **Database:** .NET increased MariaDB utilization most; production capacity is still likely bounded by MariaDB and connection pools when scaling Puma workers, not by raw Gatling RPS alone.
5. **Operations:** Always isolate the Go Compose project; stop the Rails app when load-testing rewrites against the shared test database.

---

## Follow-ups

- Add `name: wrestlingdev-go` to `go_rewrite/deploy/docker-compose-test.yml` (and ensure `local-loadtest.sh` uses it) to match .NET and prevent project collisions.
- Investigate the .NET ~10s browser delivery outlier if that path is critical.
- Re-run after compose fixes or stack changes and update the tables in this file with new report folder names and dates.
