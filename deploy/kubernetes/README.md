# How to deploy to Kubernetes

## Prerequisites
1. A storageclass named standard
2. Cert manager installed [Install Cert Manager](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html)

## Steps
1. Fill out the secrets file in `deploy/kubernetes/secrets/secrets.yaml`
2. Fill out the ingress `deploy/kubernetes/manifests/ingress.yaml` because I own wrestlingdev.com not you. Put your own domain in there.
3. Run `kubectl apply -f deploy/kubernetes/secrets/`
4. Run `kubectl apply -f deploy/kubernetes/manifests/`

## What do I get?
1. Wrestlingdev deployed with 2 replicas.
2. Two workers are deployed to run background jobs
3. A standalone mariadb that can back up to S3 compatable storage if you set the values in `deploy/kubernetes/secrets/secrets.yaml` and prometheus ready metrics
4. A standalone memcahced.

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
