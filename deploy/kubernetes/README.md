# How to deploy to Kubernetes

## Prerequisites
1. A storageclass named standard
2. Cert manager installed [Install Cert Manager](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html)

## Steps
1. Fill out the secrets file in `deploy/kubernetes/secrets/secrets.yaml`
2. Fill out the ingress `deploy/kubernetes/manifests/ingress.yaml` because I own wrestlingdev.com not you. Put your own domain in there.
3. Fill out the telemetry ingress hostnames in `deploy/kubernetes/manifests/telemetry.yaml` for Grafana and Jaeger.
4. Run `kubectl apply -f deploy/kubernetes/secrets/`
5. Run `kubectl apply -f deploy/kubernetes/manifests/`

## What do I get?
1. Wrestlingdev deployed with 2 replicas.
2. Two workers are deployed to run background jobs
3. A standalone mariadb that can back up to S3 compatable storage if you set the values in `deploy/kubernetes/secrets/secrets.yaml` and prometheus ready metrics
4. OpenTelemetry Collector, Jaeger, Prometheus, and Grafana for tracing and performance dashboards.

## Tracing and dashboards

Rails sends OTLP traces to `otel-collector:4318`. The collector exports traces to Jaeger and span metrics to Prometheus. Grafana is provisioned with the same dashboards used by the Docker Compose dev/prod tracing stack.

Jaeger all-in-one uses in-memory storage and is started with `--memory.max-traces=50000` so recent traces are available for drill-down without unbounded memory growth. Prometheus stores the dashboard span metrics separately.

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
2. Update the wrestlingdev deployment tag `kubectl --record deployment.apps/wrestlingdev-app-deployment set image deployment.v1.apps/wrestlingdev-app-deployment wrestlingdev-app=jcwimer/wrestlingdev:${TAG}`
3. Update the wrestlingdev job runner tag `kubectl --record statefulset.apps/wrestlingdev-worker set image statefulset.v1.apps/wrestlingdev-worker wrestlingdev-worker=jcwimer/wrestlingdev:${TAG}`

Finally, run db-migrations
1. Delete the db migrations job so you can re-run it `kubectl delete job wrestlingdev-db-create-migrate`
2. Re-run the db migrations job `kubectl apply -f https://raw.githubusercontent.com/jcwimer/wrestlingApp/master/deploy/kubernetes/manifests/db-migration.yaml`

## How do I see logs?

For workers: `kubectl logs -f --tail=100 -l app=wrestlingdev -l tier=worker`
For app logs: `kubectl logs -f --tail=100 -l app=wrestlingdev -l tier=app`

## I'm a pro. What's bad about this?
Right now, mariadb's root password comes from the secrets.yaml and wrestlingdev uses the root password to run. Ideally, you'd create another secret for mariadb's root password and you'd create a user specifically for wrestlingdev.
From a mysql shell> `CREATE USER ${username} IDENTIFIED BY '${password}'; GRANT ALL PRIVILEGES ON  ${database}.* TO ${username}; FLUSH PRIVILEGES;` $database would be wrestlingdev. I'll do this automatically later.

Right now, we're also only using gmail for email.
