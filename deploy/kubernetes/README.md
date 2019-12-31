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
1. Wrestlingdev deployed with 2 replicas. Autoscaling is turned on up to 4 replcias. 
2. A standalone mariadb.
3. A standalone memcahced.
4. A single job runner to run wrestlingdev background jobs.

## How do I update the app?
Each push to master updates the docker `prod` tag and also pushes a tag with the git hash.
1. Set the git hash as a variable `TAG=$(git rev-parse --verify HEAD)`
2. Update the wrestlingdev deployment tag `kubectl --record deployment.apps/wrestlingdev-app-deployment set image deployment.v1.apps/wrestlingdev-app-deployment wrestlingdev-app=jcwimer/wrestlingdev:${TAG}`
3. Update the wrestlingdev job runner tag `kubectl --record deployment.apps/wrestlingdev-worker-deployment set image deployment.v1.apps/wrestlingdev-worker-deployment wrestlingdev-worker=jcwimer/wrestlingdev:${TAG}`
4. Delete the db migrations job so you can re-run it `kubectl delete job wrestlingdev-db-create-migrate`
5. Re-run the db migrations job `kubectl apply -f deploy/kubernetes/manifests/db-migration.yaml`

## I'm a pro. What's bad about this?
Right now, mariadb's root password comes from the secrets.yaml and wrestlingdev uses the root password to run. Ideally, you'd create another secret for mariadb's root password and you'd create a user specifically for wrestlingdev.
From a mysql shell> `CREATE USER ${username} IDENTIFIED BY '${password}'; GRANT ALL PRIVILEGES ON  ${database}.* TO ${username}; FLUSH PRIVILEGES;` $database would be wrestlingdev. I'll do this automatically later.

Right now, we're also only using gmail for email.

## Recommended cloud machines
In production, this runs on GKE. I have two node pools. The first is 2 x `n2-high-cpu-2` ($12.63/month preemptible). That pool can run 1 "copy" of the application. That means 2 x app pods, 1 x worker, 1 x memcached, and 1 x mariadb. The second node pool is an autoscale from 0-10 and is of the machine type `n1-standard-1` ($7.30/ month preemptible). This pool is scritly for scaling the app pods and the worker pods.