# How to deploy to Kubernetes

## Prerequisites
1. A storageclass named standard
2. Cert manager installed [Install Cert Manager](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html)

## Steps
1. Fill out the secrets file in `deploy/kubernetes/secrets/secrets.yaml`
2. Fill out the ingress `deploy/kubernetes/manifests/ingress.yaml` because I own wrestlingdev.com not you. Put your own domain in there.
3. Fill out the telemetry ingress hostnames in `deploy/kubernetes/manifests/telemetry.yaml` for Grafana and Jaeger.
4. Run `kubectl apply -f deploy/kubernetes/secrets/`
5. Apply either `mariadb-standalone.yaml` or `mariadb-replica.yaml`, not both; they define the same database resources. Apply the remaining files in `deploy/kubernetes/manifests/`, including `telemetry.yaml`.

## What do I get?
1. Wrestlingdev deployed with 2 replicas (HPA scales to 5).
2. Solid Queue runs inside Puma (`SOLID_QUEUE_IN_PUMA=true`); there are no separate worker pods.
3. A standalone mariadb that can back up to S3 compatable storage if you set the values in `deploy/kubernetes/secrets/secrets.yaml` and prometheus ready metrics
4. OpenTelemetry Collector, Jaeger, Prometheus, and Grafana for tracing and performance dashboards.

## Tracing and dashboards

Rails sends OTLP traces to `otel-collector:4318`. The collector exports traces to Jaeger and span metrics to Prometheus. Grafana is provisioned with the same dashboards used by the Docker Compose dev/prod tracing stack.

The Grafana deployment uses an init container to download dashboard JSON files from `deploy/grafana/dashboards` on the `master` branch into `/var/lib/grafana/dashboards`. Keep dashboard edits in `deploy/grafana/dashboards`; the Kubernetes manifest only keeps the datasource and dashboard provider provisioning config.

Jaeger uses Badger storage on the `jaeger-pv-claim` PVC (15Gi requested from the default StorageClass) with seven-day retention (`--badger.span-store-ttl=168h`). Pod volume permissions allow Jaeger to run as UID 10001. Jaeger and Prometheus use `Recreate` deployments to avoid concurrent writers to their single-instance storage. Prometheus retains seven days (`--storage.tsdb.retention.time=7d`) on its existing 10Gi PVC. Retention cleanup is asynchronous; PVC capacity enforcement depends on the storage provisioner, so monitor free space.

Node exporter runs as a DaemonSet with read-only host filesystem access and host PID visibility, but no host-network port. Prometheus discovers every node-exporter pod through its headless Service. MariaDB exporter is upgraded in both database variants and is scraped through the cluster-internal `mariadb-exporter:9104` Service. It continues using the existing `dbusername`/`dbpassword` Secret keys (currently root); no new credentials are required. Neither exporter has an Ingress or NodePort. The node and MariaDB dashboards are downloaded alongside the Rails dashboards; their JSON files must exist on `master` before deploying the updated Grafana manifest.

Grafana uses the `grafana_admin_user` and `grafana_admin_password` values from `deploy/kubernetes/secrets/secrets.yaml`. Jaeger is protected with Traefik basic auth through the `wrestlingdev-jaeger-basic-auth` Secret. Generate the Jaeger value with `htpasswd -nbB admin 'your-password-here'` and put the full output in `stringData.users`.

The telemetry ingress defaults to:

* Grafana: `grafana.wrestlingdev.com`
* Jaeger: `jaeger.wrestlingdev.com`

If you deploy into a namespace other than `default`, update the Jaeger ingress middleware annotation from `default-wrestlingdev-jaeger-basic-auth@kubernetescrd` to match your namespace.

## How do I update the app?
First, be sure your secrets.yaml has all envs up to date. Then, make sure you get all manifest changes
1. Run `kubectl apply -f https://raw.githubusercontent.com/jcwimer/wrestlingApp/master/deploy/kubernetes/manifests/wrestlingdev.yaml`

Each push to master updates the docker `prod` tag and also pushes a tag with the git hash. You will want to update to those tags.
1. Set the git hash as a variable `TAG=$(git rev-parse --verify HEAD)`
2. Update the app image `kubectl --record statefulset.apps/wrestlingdev-app set image statefulset.v1.apps/wrestlingdev-app wrestlingdev-app=jcwimer/wrestlingdev:${TAG}`

Finally, run db-migrations
1. Delete the db migrations job so you can re-run it `kubectl delete job wrestlingdev-db-create-migrate`
2. Re-run the db migrations job `kubectl apply -f https://raw.githubusercontent.com/jcwimer/wrestlingApp/master/deploy/kubernetes/manifests/db-migration.yaml`

## How do I see logs?

`kubectl logs -f --tail=100 -l app=wrestlingdev -l tier=frontend`

## I'm a pro. What's bad about this?
Right now, mariadb's root password comes from the secrets.yaml and wrestlingdev uses the root password to run. Ideally, you'd create another secret for mariadb's root password and you'd create a user specifically for wrestlingdev.
From a mysql shell> `CREATE USER ${username} IDENTIFIED BY '${password}'; GRANT ALL PRIVILEGES ON  ${database}.* TO ${username}; FLUSH PRIVILEGES;` $database would be wrestlingdev. I'll do this automatically later.

Right now, we're also only using gmail for email.
