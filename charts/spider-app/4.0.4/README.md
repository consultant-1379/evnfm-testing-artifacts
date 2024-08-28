# Introduction

Spider Application is an integration helm chart containing most ADP Generic Services with test applications

# How to install

## Create a values.yaml

Create site.specific.values.yaml.

```
eric-adp-gs-testapp:
  ingress:
    hosts:
      - eric-adp-gs-testapp.<NAMESPACE>.<HOSTNAME>
  snmpAlarmProvider:
    hostname: <HOSTNAME>
    port: 44162
eric-dst-jg:
  query:
    ingress:
      hosts:
        - eric-dst-jg.<NAMESPACE>.<HOSTNAME>
eric-fh-snmp-alarm-provider:
  ingress:
    snmpAgentPort: 44162
eric-lcm-helm-chart-registry:
  ingress:
    host: eric-lcm-helm-chart-registry.<NAMESPACE>.<HOSTNAME>
eric-lcm-container-registry:
  ingress:
    host: eric-lcm-container-registry.<NAMESPACE>.<HOSTNAME>
eric-pm-bulk-reporter:
  service:
    servicePort: 44022
eric-pm-server:
  server:
    ingress:
      hosts:
        - eric-pm-server.<NAMESPACE>.<HOSTNAME>
eric-sec-access-mgmt:
  ingress:
    host: eric-sec-access-mgmt.<NAMESPACE>.<HOSTNAME>
iam-test-app:
  iam:
    namespace: <NAMESPACE>
  ingress:
    host: iam-test-app.<NAMESPACE>.<HOSTNAME>
influxdb:
  ext:
    apiAccessHostname: influxdb-service.<NAMESPACE>.<HOSTNAME>
pm-testapp:
  ingress:
    domain: <HOSTNAME>
eric-cm-yang-provider:
  service:
    cliPort: 2022
    netconfPort: 2830
```

Warn: services using L4 ingress with service port, make sure port is changed when deploying the service multiple times on the same k8 clusters.

Replace all NAMESPACE and HOSTNAME

```
sed -i 's/<HOSTNAME>/adpci06.seli.gic.ericsson.se/g' site.specific.values.yaml
sed -i 's/<NAMESPACE>/mysignum/g' site.specific.values.yaml
```

## Install full spider-app helm chart

```
$ helm repo add spider-team https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-spider-team-helm/
$ helm install --name spider-app-mysignum spider-team/spider-app -f site.specific.values.yaml --namespace mysignum
```

Check that test service is installed

```
$ helm ls
NAME           	    REVISION	UPDATED                 	STATUS  	CHART             	NAMESPACE
nfs-provisioner	    1       	Tue Nov  7 02:30:32 2017	DEPLOYED	nfs-provider-0.1.0	default
spider-app-mysignum	1       	Fri Nov 10 17:16:23 2017	DEPLOYED	spider-app-1.25.0   mysignum
$ kubectl get all -n mysignum
```

## Install all spider-app helm chart with SIP-TLS disabled(In default SIP-TLS will be installed, only when you want to disable it)

```
$ helm repo add spider-team https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-spider-team-helm/
$ helm install --name spider-app-mysignum spider-team/spider-app -f site.specific.values.yaml --namespace mysignum --set eric-sec-key-management.images.ca.enabled=true --set eric-sec-key-management.withSipTls=false --set key-management-test-app.withSipTls=false
```
``

## Install sub-part of spider-app helm chart

```
$ helm install --name spider-app-mysignum spider-team/spider-app -f site.specific.values.yaml --namespace mysignum --set tags.all=false --set tags.logging=true
```

## Current tag list

See requirements.yaml for full list:

```
logging
  - eric-log-shipper
  - eric-log-transformer
  - eric-data-search-engine
  - eric-data-search-engine-curator
  - eric-dst-jg
  - log-test-app (TEST)
  - influxdb (TEST)
alarm
  - eric-data-message-bus-kf
  - eric-data-coordinator-zk
  - eric-data-document-database-pg
  - eric-fh-alarm-handler
  - eric-fh-snmp-alarm-provider
  - eric-adp-gs-testapp (TEST)
idam
  - eric-sec-access-mgmt
  - eric-data-document-database-pg
  - iam-test-app (TEST)
km
  - eric-sec-key-management
  - key-management-test-app (TEST)
  - influxdb (TEST)
cm
  - eric-data-document-database-pg
  - eric-cm-mediator
  - eric-cm-yang-provider
  - eric-cm-yang-provider-testapp (TEST)
  - cm-loadtest (TEST)
  - cm-subscriber (TEST)
  - influxdb (TEST)
pm
  - eric-pm-server
  - eric-pm-bulk-reporter
  - pm-testapp (TEST)
  - pm-testapp-controller (TEST)
  - influxdb (TEST)
  - eric-adp-gs-testapp (TEST)
kafka
  - eric-data-message-bus-kf
  - eric-data-coordinator-zk
  - eric-adp-gs-testapp (TEST)
geode
  - eric-data-kvdb-ag
  - eric-adp-gs-testapp (TEST)
cassandra
  - eric-data-wide-column-database-cd
  - eric-adp-gs-testapp (TEST)
consul
  - eric-adp-gs-testapp (TEST)
postgres
  - eric-data-document-database-pg (alias: eric-adp-gs-testapp-db-pg)
  - eric-adp-gs-testapp (TEST)
helm
  - eric-lcm-helm-chart-registry
container
  - eric-lcm-container-registry
sctp
  - eric-tm-sctp
  - sctp-adp-staging-testapp
ldap
  - eric-sec-ldap-server
  - eric-sec-key-management
  - eric-sec-access-mgmt
  - eric-sec-sip-tls
  - eric-data-distributed-coordinator-ed
  - eric-data-document-database-pg
  - ldap-test-app (TEST)
etcd
  - eric-data-distributed-coordinator-ed
ingress
  - eric-tm-ingress-controller-cr
ddc
  - eric-odca-diagnostic-data-collector
  - eric-log-shipper
  - eric-log-transformer
  - eric-data-search-engine
  - log-test-app (TEST)
  - influxdb (TEST)
certm
  - eric-sec-certm
  - eric-cm-mediator
  - eric-data-document-database-pg
  - eric-cm-yang-provider
  - eric-cm-yang-provider-testapp (TEST)
  - cm-loadtest (TEST)
  - cm-subscriber (TEST)
  - influxdb (TEST)
bro
  - eric-ctrl-bro
```
