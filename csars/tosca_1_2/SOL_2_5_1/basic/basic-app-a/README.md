# Basic App A

## Description

This csar contains one helm chart which is a simplest example implementation of
[ADP HELM Chart Design Rules and Guidelines](https://confluence.lmera.ericsson.se/display/AA/HELM+Chart+Design+Rules+and+Guidelines)

Features included:
- fast life-cycle operation (sub 1 minute)
- you can control readiness of the pod by setting value probesConfig.readinessProbe.delayBeforeReady (in seconds)
- day0 configuration (will create secret in ns during instantiation and automatically delete it after it completes
- scale interface
- rollback interface (rollback feature will be available if Basic App A is upgraded with this package)
