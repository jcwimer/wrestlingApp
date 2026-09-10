Audit this Rails app for deviations from supported Rails and gem best practices for the versions actually in use.

## Goal
Find only changes that increase upgrade risk, rely on unsupported/deprecated APIs, or diverge from official gem configuration guidance — not normal application code.

## Version discovery (do this first)
Before auditing, determine the exact versions in use from the repo — do not assume or hardcode versions:
- **Rails**: `Gemfile` and `Gemfile.lock` (e.g. `gem 'rails', ...` and the locked `rails (...)` entry)
- **Ruby**: `.ruby-version` and/or `Gemfile` `ruby` directive
- **Relevant gems**: locked versions in `Gemfile.lock` for gems under audit (at minimum: OpenTelemetry gems, Prosopite, Solid Queue, sqlite3, and any other gems whose config you review)

Use the discovered Rails version’s official guides, release notes, and API docs as the baseline. Use each gem’s docs/README for the locked gem version (or the closest documented release) as the gem baseline.

## Read first
Before reporting anything, read `AGENTS.md` section "Accepted non standard rails patterns and implementations". Do NOT report items already documented there unless you find they are implemented incorrectly or no longer match current Rails/gem docs for the locked versions.

## Report ONLY items that meet at least one of these criteria
1. **Unsupported or deprecated Rails API usage** — monkey patches, reopening core classes, `class_eval` on framework code, removed/changed APIs for the locked Rails version, config options not documented for that version
2. **Non-default Rails configuration with upgrade impact** — `config/application.rb`, `config/environments/*`, `config/initializers/*`, `config/database.yml` settings that differ from that Rails version’s defaults AND are not listed in AGENTS.md
3. **Framework bypass patterns** — raw SQL where Active Record is expected, custom connection handling, manual job/worker wiring that conflicts with Solid Queue’s supported setup for the locked version
4. **Gem misuse or non-standard gem integration** — especially:
   - **OpenTelemetry** (`config/initializers/opentelemetry.rb`, related deploy config): compare against official Ruby OTEL Rails integration docs for the locked OTEL gem versions; flag deprecated exporters, unsupported auto-instrumentation, or config that fights Rails’ built-in tracing hooks
   - **Prosopite**: compare against Prosopite docs for the locked version; flag only if setup conflicts with the locked Rails/SQLite usage (note: disabled prepared statements in dev/test for Prosopite fingerprinting is intentional — do not flag)
5. **Documented intentional deviations implemented wrong** — e.g. Solid Queue via Puma plugin, SQLite WAL/busy timeout — only if the code doesn’t match AGENTS.md or current gem docs for the locked versions

## Do NOT report (these are false positives)
- Normal domain logic: models, services, controllers, concerns, presenters, policies
- Standard Rails stack choices for the locked version: importmap, Hotwire, Active Job, Solid Queue, Action Cable, standard test structure
- Environment-specific DB (SQLite dev/test, MariaDB production) unless the *configuration* itself is wrong
- Docker/Kubernetes/Jenkins/Prometheus/Grafana deployment choices (unless they change Rails boot/config in unsupported ways)
- “Could be done differently” stylistic opinions
- Features that are non-default but officially supported and documented in Rails guides for the locked version

## For each finding, provide
| Field | Required |
|-------|----------|
| **Risk** | High / Medium / Low — based on upgrade breakage likelihood |
| **Category** | Rails config / Monkey patch / Deprecated API / Gem config / Other |
| **Location** | File path + line range |
| **What deviates** | One sentence: what differs from Rails or gem defaults for the locked versions |
| **Evidence** | Quote the config/code; cite the Rails or gem doc section it conflicts with (for the version in use) |
| **Why it matters** | Concrete upgrade/maintenance risk |
| **Recommendation** | Align with standard, keep as-is (document), or investigate further |

## Output format
1. **Versions audited** — Rails, Ruby, and key gem versions read from the repo
2. **Summary** — count by risk level
3. **Findings** — table or list using the fields above; highest risk first
4. **Reviewed and excluded** — brief list of things checked but intentionally not reported (proves you read AGENTS.md and avoided false positives)
5. **No findings** — if nothing qualifies, say so explicitly and list what you audited

## Constraints
- Cite actual files; do not speculate from memory
- If unsure whether something is supported for the locked Rails/gem version, say "uncertain" and which doc to verify — do not guess
- Prefer official Rails guides and release notes for the locked Rails version, and each gem’s current README/docs for the locked gem version, over blog posts
- If a finding is a supported Rails or gem-documented pattern for the locked versions, it must go in "Reviewed and excluded", not "Findings"
