
## Configuration

The following tables lists the configurable parameters of the PM Server chart and their default values.

Parameter | Description | Default
--------- | ----------- | -------
`affinity.podAntiAffinity` | Define inter-pod anti-affinity policy to kubernetes scheduler. Supported values are "hard" and "soft". | `"hard"`
`affinity.topologyKey` | Determine domain for Pod placement on nodes based on label matching. | `"kubernetes.io/hostname"`
`annotations` | List of additional key/value pairs of annotations appended to every resource object created within PM Server. | `{}`
`appArmorProfile.eric-pm-configmap-reload.localhostProfile` | The 'localhost' profile requires a profile name to be provided. The name of the local appArmor profile to be used for eric-pm-configmap-reload container. | `""`
`appArmorProfile.eric-pm-configmap-reload.type` | Configuration of AppArmor profile type for eric-pm-configmap-reload container. Supported values are unconfined, runtime/default, localhost and "". | `""`
`appArmorProfile.eric-pm-initcontainer.localhostProfile` | The 'localhost' profile requires a profile name to be provided. The name of the local appArmor profile to be used for eric-pm-initcontainer container. | `""`
`appArmorProfile.eric-pm-initcontainer.type` | Configuration of AppArmor profile type for eric-pm-initcontainer container. Supported values are unconfined, runtime/default, localhost and "". | `""`
`appArmorProfile.eric-pm-exporter.localhostProfile` | The 'localhost' profile requires a profile name to be provided. The name of the local appArmor profile to be used for eric-pm-exporter container. | `""`
`appArmorProfile.eric-pm-exporter.type` | Configuration of AppArmor profile type for eric-pm-exporter container. Supported values are unconfined, runtime/default, localhost and "". | `""`
`appArmorProfile.eric-pm-reverseproxy.localhostProfile` | The 'localhost' profile requires a profile name to be provided. The name of the local appArmor profile to be used for eric-pm-reverseproxy container. | `""`
`appArmorProfile.eric-pm-reverseproxy.type` | Configuration of AppArmor profile type for eric-pm-reverseproxy container. Supported values are unconfined, runtime/default, localhost and "". | `""`
`appArmorProfile.eric-pm-server.localhostProfile` | The 'localhost' profile requires a profile name to be provided. The name of the local appArmor profile to be used for eric-pm-server container. | `""`
`appArmorProfile.eric-pm-server.type` | Configuration of AppArmor profile type for eric-pm-server container. Supported values are unconfined, runtime/default, localhost and "". | `""`
`appArmorProfile.ericsecoauthsap.localhostProfile` | The 'localhost' profile name for the ericsecoauthsap container if type is 'localhost' | `""`
`appArmorProfile.ericsecoauthsap.type` | The AppArmor type for the ericsecoauthsap container ("unconfined", "runtime/default", "localhost", "") | `""`
`appArmorProfile.ericsecoauthproxy.localhostProfile` | The 'localhost' profile name for the ericsecoauthproxy container if type is 'localhost' | `""`
`appArmorProfile.ericsecoauthproxy.type` | The AppArmor type for the ericsecoauthproxy container ("unconfined", "runtime/default", "localhost", "") | `""`
`appArmorProfile.hooklauncher.localhostProfile` | Localhost profile name for hooklauncher container if appArmorProfile.hooklauncher.type is localhost | `""`
`appArmorProfile.hooklauncher.type` | Configuration for AppArmor profile type for the hooklauncher container. Supported values are unconfined, runtime/default, localhost and "". | `""`
`appArmorProfile.logshipper.localhostProfile` | The 'localhost' profile requires a profile name to be provided. The name of the local appArmor profile to be used for logshipper container. | `""`
`appArmorProfile.logshipper.type` | Configuration of AppArmor profile type for logshipper container. Supported values are unconfined, runtime/default, localhost and "". | `""`
`appArmorProfile.localhostProfile` | The 'localhost' profile requires a profile name to be provided. The name of the local appArmor profile to be used. The setting applies to all container when the container specific parameter is omitted. | `""`
`appArmorProfile.type` | Configuration of AppArmor profile type. The setting applies to all container when the container specific parameter is omitted. Supported values are unconfined, runtime/default, localhost and "". | `""`
`authorizationProxy.adpIamAdminSecret` | Name of k8s secret providing IAM admin credentials. Must have the same value as `statefulset.adminSecret` in IAM server | `eric-sec-access-mgmt-creds`
`authorizationProxy.adpIamClientCredentialSecret` | Name of k8s secret providing IAM client credentials. Relevant only when TLS is disabled (TLS shouldn't be disabled in production, only in customer demos and similar). Must have the same value as `authenticationProxy.clientCredentialSecret` in IAM server | `"eric-sec-access-mgmt-creds"`
`authorizationProxy.adpIamRealm` | ADP IAM realm name used by Authorization Proxy | `oam`
`authorizationProxy.adpIamServiceName` | Name of ADP IAM service (=chart name) | `eric-sec-access-mgmt`
`authorizationProxy.adpIamServicePort` | ADP IAM k8s service port (Authorization proxy will use 8443 or 8080 depending on if TLS is enabled or not) | `""`
`authorizationProxy.adpIccrServiceName` | Name of ADP ICCR service (=chart name). Obsolete if `authorizationProxy.adpIccrCaSecret` is set | `eric-tm-ingress-controller-cr`
`authorizationProxy.adpIccrCaSecret` | Name of the k8s secret containing ADP ICCR client certificate CA(s). Must be set if ADP ICCR Envoy client certificates are enabled and ICCR client certificate CA(s) is stored in non-default k8s secret. For Envoy client certificate settings and ICCR CA k8s secret name, see [Ingress Controller CR][ICCR] | `commented out`
`authorizationProxy.adpIamClientCredentialSecret` | IAM Client credential secret.  The name of k8s secret providing IAM client credentials. Relevant only when TLS is disabled (TLS shouldn't be disabled in production, only in customer demos and similar). Must have the same value as authenticationProxy.clientCredentialSecret in IAM server. | ``
`authorizationProxy.authzLog.logtransformer.host` | LogTransformer host for logging | ``
`authorizationProxy.enabled` | Enable external exposure of PM Metrics Query and Management API | `false`
`authorizationProxy.iamRequestTimeout` | Timeout for authorization interrogation which is sent to IAM server. Authorization Proxy waits for reply iamRequestTimeout seconds after which it replies with 503 code to downstream | `8`
`authorizationProxy.localSpClientCertVolumeName` | Client certificate volume name | ``
`authorizationProxy.localSpPort` | The port number of PM Server service in localhost where Authorization Proxy forwards the authorized HTTP requests. Used if `authorizationProxy.enabled` is true | `9090`
`authorizationProxy.port` | Authorization Proxy container port. Authorization Proxy will reserve two ports numbers: `authorizationProxy.port` and `authorizationProxy.port-1` (used by k8s probes). By default Authorization Proxy therefore reserves port numbers 8887 and 8888.  |  `8888`
`authorizationProxy.protectedPaths` | List of externally published resource paths which will be protected by Authorization Proxy | `[/api/v1/query]`
`authorizationProxy.resources.ericsecoauthproxy.limits.cpu` | CPU limit for ericsecoauthproxy container | ``
`authorizationProxy.resources.ericsecoauthproxy.limits.ephemeral-storage` | Ephemeral-storage limit for ericsecoauthproxy container | ``
`authorizationProxy.resources.ericsecoauthproxy.limits.memory` | Memory limit for ericsecoauthproxy container | ``
`authorizationProxy.resources.ericsecoauthproxy.requests.cpu` | CPU request for ericsecoauthproxy container | ``
`authorizationProxy.resources.ericsecoauthproxy.requests.ephemeral-storage` | Ephemeral-storage request for ericsecoauthproxy container | ``
`authorizationProxy.resources.ericsecoauthproxy.requests.memory` | Memory request for ericsecoauthproxy container | ``
`authorizationProxy.resources.ericsecoauthsap.limits.cpu` | CPU limit for ericsecoauthsap container | ``
`authorizationProxy.resources.ericsecoauthsap.limits.ephemeral-storage` | Ephemeral-storage limit for ericsecoauthsap container | ``
`authorizationProxy.resources.ericsecoauthsap.limits.memory` | Memory limit for ericsecoauthsap container | ``
`authorizationProxy.resources.ericsecoauthsap.requests.cpu` | CPU request for ericsecoauthsap container | ``
`authorizationProxy.resources.ericsecoauthsap.requests.ephemeral-storage` | Ephemeral-storage request for ericsecoauthsap container | ``
`authorizationProxy.resources.ericsecoauthsap.requests.memory` | Memory request for ericsecoauthsap | ``
`authorizationProxy.sipoauth2.enabled` | (deprecated) Enables or disables Authorization Proxy to use IAM sip-oauth2 API to get identity when communicating with IAM | `true`
`authorizationProxy.spRequestTimeout` | Timeout for HTTP request which is forwarded to the PM Server. Authorization Proxy waits for reply spRequestTimeout seconds after which it replies with 503 code to downstream | `8`
`authorizationProxy.suffixOverride` | Authorization k8s service name suffix. Used for generating SP specific cluster wide unique k8s service name. The name format is &lt;service-provider-chart-name&gt; + "-" + suffixOverride. **_Note_**: it is not recommended to leave this variable empty as there may be name collisions between resources | `authproxy`
`bandwidth.maxEgressRate` | The maximum rate in megabit-per-second at which traffic can leave the pod (Example: `bandwidth.maxEgressRate: 10M` for 10Mbps). This parameter is being deprecated, please use bandwidth.eric-pm-server.maxEgressRate | `""`
`bandwidth.eric-pm-server.maxEgressRate` | The maximum rate in megabit-per-second at which traffic can leave the pod (Example: `bandwidth.eric-pm-server.maxEgressRate: 10M` for 10Mbps) | `""`
`bandwidth.hooklauncher.maxEgressRate` | The maximum rate in megabit-per-second at which traffic can leave the pod | ``
`config.alerting` | This is an alpha feature. Configure the AlertManager target details here so that the Prometheus can process the rules and send the alerts to the targets defined here. Prometheus will trigger the alerts based on the rules defined under recording_rules. For more information please refer to Maturing Features Section above. | `{}`
`config.certm_tls` | TLS configuration for certm. Multiple endpoints can be configured | `[]`
`config.certm_tls.clientCertName` | Same name as used in the CLI action `keystore asymmetric-keys install-asymmetric-key-pkcs12 name <clientKeyName> certificate-name <clientCertName> ...` | `commented out`
`config.certm_tls.clientKeyName` | Same name as used in the CLI action `keystore asymmetric-keys install-asymmetric-key-pkcs12 name <clientKeyName> certificate-name <clientCertName> ...` | `commented out`
`config.certm_tls.name` | Name of the endpoint | `commented out`
`config.certm_tls.trustedCertName` | Same name as used in the CLI action `install-certificate-pem name <trustedCertName> pem ...` | `commented out`
`config.recording_rules` | Define recording rules | `{}`
`config.remote_write` | Define remote write endpoints | `[]`
`global.networkPolicy.enabled` | Global configuration parameter to enable/disable Network Policy for the HTTP(s) and the metrics port of PM Server. Both global and service-level parameters have to be set to `true` for the Network Policy to be deployed. When enabled, the metrics ports of PM Server allow ingress from the PM Bulk Reporter, set via `.Values.security.tls.pmBulkReporter.serviceName`. Services which want to access the HTTP(s) port of PM Service, require the label `eric-pm-service-access: "true"`. | `false`
`global.annotations` | Global annotations | ``
`global.labels` | Global labels | ``
`global.log.outputs` | Global logging outputs | ``
`global.log.streamingMethod` | Global logging streaming methods | ``
`global.pullSecret` | PM Server's global registry pull secret  | `commented out`
`global.registry.imagePullPolicy` | Global registry image pull policy | ``
`global.registry.pullSecret` | (deprecated) PM Server's global registry pull secret  | `commented out`
`global.registry.repoPath` | PM Server's global image Repository Path. | `commented out`
`global.registry.url`| PM Server's image global registry. | `armdocker.rnd.ericsson.se`
`global.timezone`| PM Server's timezone setting | `UTC`
`global.security.policyBinding.create` | Creates Pod Security Policy (PSP) | `commented out`
`global.security.policyReferenceMap` | Creates Reference Map for Pod Security Policy (PSP) | `commented out`
`global.security.policyReferenceMap.default-restricted-security-policy` | Creates a restricted security policy | ``
`global.security.tls.enabled` | PM Server TLS support | `true`
`global.security.securityPolicy.rolekind` | Configuration of the security policy role kind. | ``
`global.hooklauncher.executor` | If set to `service`, hooks for handling upgrades and rollbacks will be executed by this chart. If set to `integration`, hooks for handling upgrades and rollbacks will be executed by a Hooklauncher in the containing integration chart (not supported yet). | `service`
`global.nodeSelector` | Node labels for PM server pod assignment. | `{}`
`hooklauncher.backoffLimit` | Back off limit for hooklauncher | ``
`hooklauncher.cleanup` | Clean up for hooklauncher | ``
`hooklauncher.terminateEarlyOnFailure` | Terminate Early on Failure for hooklauncher | ``
`imageCredentials.eric-pm-configmap-reload.repoPath` | PM Configmap Reload image path. It overrides service, global and default repository path for the image | `""`
`imageCredentials.eric-pm-exporter.repoPath` | PM Exporter image path. It overrides service, global and default repository path for the image | `""`
`imageCredentials.eric-pm-initcontainer.repoPath` | PM Init container image path. It overrides service, global and default repository path for the image | `""`
`imageCredentials.eric-pm-reverseproxy.repoPath` | PM Reverse proxy image path. It overrides service, global and default repository path for the image | `""`
`imageCredentials.eric-pm-server.repoPath` | PM Server image path. It overrides service, global and default repository path for the image | `""`
`imageCredentials.ericsecoauthproxy.registry.imagePullPolicy` | Authorization Proxy image pull policy | `""`
`imageCredentials.ericsecoauthproxy.registry.url` | Authorization Proxy docker image repository | `""`
`imageCredentials.ericsecoauthproxy.repoPath` | Relative image path for sidecar container image within the above url | `""`
`imageCredentials.ericsecoauthsap.registry.imagePullPolicy` | Authorization sap init container image pull policy | `""`
`imageCredentials.ericsecoauthsap.registry.url` | Authorization sap init container docker image repository | `""`
`imageCredentials.ericsecoauthsap.repoPath` | Relative path for sap init container image within the above url | `""`
`imageCredentials.hooklauncher.registry.url` | The Smart Helm Hook docker image repository | `""`
`imageCredentials.hooklauncher.registry.imagePullPolicy` | The Smart Helm Hook image pull policy | `""`
`imageCredentials.hooklauncher.repoPath` | The path to the Smart Helm Hook repository within the above url | `""`
`imageCredentials.logshipper.registry.url`| The Log shipper docker image repository | `""`
`imageCredentials.logshipper.registry.imagePullPolicy`| The Log Shipper image pull policy | `""`
`imageCredentials.logshipper.repoPath`| The path to the Log Shipper repository within the above url | `proj-adp-log-released`
`imageCredentials.pullPolicy`| PM Server container images pull Policy. | `IfNotPresent`
`imageCredentials.pullSecret` | PM Server's registry pull secret  | `commented out`
`imageCredentials.registry.imagePullPolicy` | Image credentials registry image pull policy | ``
`imageCredentials.registry.pullSecret` | (deprecated) PM Server's registry pull secret. | `commented out`
`imageCredentials.registry.url`| Overrides global registry url. | `""`
`imageCredentials.repoPath`| PM Server's image path. | `proj-common-assets-cd-docker-global/monitoring/pm`
`images` | Images | ``
`ingress.annotations` | Annotations for Ingress | ``
`ingress.certificates.asymmetricKeyCertificateName` | Certificate and corresponding key name (/) used when requesting certificates from Certificate Management. The format should be &lt;keyName&gt;/&lt;certName&gt; | `"pm-query-server-key/pm-query-server-certificate"`
`ingress.certificates.caSecret` | Ingress certificate authority secret | ``
`ingress.certificates.secretName` | Ingress secret name for certificate | ``
`ingress.certificates.trustedCertificateListName` | Used when requesting a CA from Certificate Management | `"pm-query-server-ca"`
`ingress.enabled` | Provides access from outside cluster to path `/api/v1/query` when enabling external exposure of PM Metrics Query and Management API | `false`
`ingress.hostname` | Ingress host fully qualified domain name (FQDN). Mandatory if `ingress.enabled` is true | `""`
`ingress.ingressClass | Sets ingress class name indicating which ingress controller instance is consuming the ingress resource |
`labels` | List of key/value pairs of labels appended to every resource object created in PM Server. | `{}`
`log.streamingMethod` | Logging streaming method | ``
`logLevel` | Supported values: debug, info, warning, error. Decides log level of containers. | `info`
`log.format` | Services will generate logs according to the ADP JSON log if log.format is set to json, otherwise, there will be an issue related to incorrect severity. This parameter will be deprecated in the near feature | `""`
`logShipper.logLevel`| log level of log shipper, when enabled | `info`
`logShipper.output.logTransformer.host`| Log Shipper, Log transformer host | `eric-log-transformer`
`logShipper.storage.size`| Size of the shared volume | `1Gi`
`logShipper.storage.medium` | Options avaliable: Memory or Ephemeral. When the value is set as Memory, emptyDir volumes will be selected to setup tmpfs (RAM-backed filesystem), this will impact log producer memory dimensioning | `Ephemeral`
`logShipper.input.files.enabled` | Enable or disable input | `true`
`logShipper.input.files.paths` | List of files to ship relative from logShipper.storage.path. Wildcards are supported, but not recommended to use | `["configmap-reload.log", "pm-initenv.log", "pm-reverseproxy.log", "pm-exporter.log", "pm-server.log", "pm-promxy.log"]`
`nameOverride` | Overrides the name | ``
`networkPolicy.enabled`| Enable creation of NetworkPolicy resources. | `true`
`nodeSelector` | Node labels for PM server pod assignment. This parameter is being deprecated, please use nodeSelector.eric-pm-server | `{}`
`nodeSelector.eric-pm-server` | Service-level parameter of node labels for PM Server pod assignment. | `{}`
`nodeSelector.hooklauncher` | Service-level parameter of node labels for Hooklauncher Pod assignment. | `{}`
`podDisruptionBudget.minAvailable` | Minimum available pods | `0`
`podPriority.eric-pm-server.priorityClassName` | The configuration of the priority class for the PM Server pod(s) assigning importance relative to other pods. | `""`
`podPriority.eric-pm-server-promxy.priorityClassName` | The configuration of the priority class for the PM Server Promxy pod(s) assigning importance relative to other pods. | `""`
`podPriority.hooklauncher.priorityClassName` | The configuration of the priority class for the Smart Helm Hook pod(s) assigning importance relative to other pods. | `""`
`podPriority.priorityClassName` | Priority class name for pod priority | ``
`probes.configmapreload.readinessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `30`
`probes.configmapreload.readinessProbe.periodSeconds` | Interval, in seconds, between readiness probes.| `10`
`probes.configmapreload.readinessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `30`
`probes.configmapreload.readinessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `3`
`probes.configmapreload.readinessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`probes.configmapreload.livenessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `30`
`probes.configmapreload.livenessProbe.periodSeconds` | Interval, in seconds, between liveness probes.| `10`
`probes.configmapreload.livenessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `15`
`probes.configmapreload.livenessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `3`
`probes.configmapreload.livenessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`probes.ericsecoauthproxy.livenessProbe.initialDelaySeconds` | initialDelaySeconds for livenessProbe of ericsecoauthproxy sidecar container | `0`
`probes.ericsecoauthproxy.livenessProbe.failureThreshold`	| Number of failures before considering the liveness probe to have failed | `1`
`probes.ericsecoauthproxy.livenessProbe.periodSeconds` | Interval, in seconds, between liveness probes of ericsecoauthproxy sidecar container | `5`
`probes.ericsecoauthproxy.livenessProbe.timeoutSeconds`	| Number of seconds to allow before the probe times out | `5`
`probes.ericsecoauthproxy.readinessProbe.initialDelaySeconds` | initialDelaySeconds for readinessProbe of ericsecoauthproxy sidecar container | `0`
`probes.ericsecoauthproxy.readinessProbe.failureThreshold` | Number of failures before considering the readiness probe to have failed | `1`
`probes.ericsecoauthproxy.readinessProbe.periodSeconds`	| Interval, in seconds, between readiness probes of ericsecoauthproxy sidecar container | `5`
`probes.ericsecoauthproxy.readinessProbe.successThreshold` | Number of successes before considering the readiness probe of ericsecoauthproxy sidecar container successful | `1`
`probes.ericsecoauthproxy.readinessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out | `5`
`probes.ericsecoauthproxy.startupProbe.initialDelaySeconds` | initialDelaySeconds for startupProbe of ericsecoauthproxy sidecar container | `0`
`probes.ericsecoauthproxy.startupProbe.failureThreshold` | Number of failures before considering the startup probe to have failed | `25`
`probes.ericsecoauthproxy.startupProbe.periodSeconds`	| Interval, in seconds, between startup probes of ericsecoauthproxy sidecar container | `5`
`probes.ericsecoauthproxy.startupProbe.timeoutSeconds` | Number of seconds to allow before the probe times out | `5`
`probes.exporter.readinessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `5`
`probes.exporter.readinessProbe.periodSeconds` | Interval, in seconds, between readiness probes.| `15`
`probes.exporter.readinessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `15`
`probes.exporter.readinessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `3`
`probes.exporter.readinessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`probes.exporter.livenessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `15`
`probes.exporter.livenessProbe.periodSeconds` | Interval, in seconds, between liveness probes.| `15`
`probes.exporter.livenessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `15`
`probes.exporter.livenessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `3`
`probes.exporter.livenessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`probes.logshipper.livenessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `1`
`probes.logshipper.livenessProbe.periodSeconds` | Interval, in seconds, between liveness probes.| `10`
`probes.logshipper.livenessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `10`
`probes.logshipper.livenessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `3`
`probes.logshipper.livenessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`probes.promxy.readinessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `5`
`probes.promxy.readinessProbe.periodSeconds` | Interval, in seconds, between readiness probes.| `5`
`probes.promxy.readinessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `3`
`probes.promxy.readinessProbe.failureThreshold` | Number of failures before the probe times out. | `120`
`probes.promxy.readinessProbe.successThreshold` | Number of successes before considering the probe to have failed. | `1`
`probes.promxy.livenessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `5`
`probes.promxy.livenessProbe.periodSeconds` | Interval, in seconds, between liveness probes.| `5`
`probes.promxy.livenessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `3`
`probes.promxy.livenessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `6`
`probes.promxy.livenessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`probes.server.readinessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `30`
`probes.server.readinessProbe.periodSeconds` | Interval, in seconds, between readiness probes.| `10`
`probes.server.readinessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `30`
`probes.server.readinessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `3`
`probes.server.readinessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`probes.server.livenessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `30`
`probes.server.livenessProbe.periodSeconds` | Interval, in seconds, between liveness probes.| `10`
`probes.server.livenessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `15`
`probes.server.livenessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `3`
`probes.server.livenessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`probes.reverseproxy.readinessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `5`
`probes.reverseproxy.readinessProbe.periodSeconds` | Interval, in seconds, between readiness probes.| `15`
`probes.reverseproxy.readinessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `15`
`probes.reverseproxy.readinessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `3`
`probes.reverseproxy.readinessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`probes.reverseproxy.livenessProbe.initialDelaySeconds` | Delay, in seconds, before Kubernetes starts polling the service for liveness. This value may have to be increased if pod restarts are occurring.| `15`
`probes.reverseproxy.livenessProbe.periodSeconds` | Interval, in seconds, between liveness probes.| `15`
`probes.reverseproxy.livenessProbe.timeoutSeconds` | Number of seconds to allow before the probe times out. | `15`
`probes.reverseproxy.livenessProbe.failureThreshold` | Number of failures before considering the probe to have failed. | `3`
`probes.reverseproxy.livenessProbe.successThreshold` | Number of successes before considering the probe successful. | `1`
`promxy.antiAffinity` | anti-affinity for merging values in time series between prometheus instances in server_group. PQAP will not merge any datapoint within this value of another datapoint. Suggested value is the scrape interval | `"15s"`
`promxy.configMapOverrideName` | If set, use the provided configmap for promxy | `""`
`promxy.dialTimeout` | How long promxy will wait for a connection to Prometheus's targets | `"1s"`
`promxy.dynamicDiscovery.enabled` | Use static/dynamic discovery for targets | `true`
`promxy.endpoints.pmScrapeTarget.tls.enforced` | The option controls if cleartext and TLS or only TLS is allowed on the PM query interface. Value optional allows both cleartext and TLS. Value required allows only TLS. | `required`
`promxy.endpoints.pmScrapeTarget.tls.verifyClientCertificate` | It checks whether the client connection toward PM Promxy using TLS requires authentication or not. By default it is required, otherwise set it as optional. | `required`
`promxy.env` | Promxy environment | ``
`promxy.extraArgs` | Additional arguments for promxy | `{}`
`promxy.extraLabels` | Additional labels for promxy | `{}`
`promxy.metricPath` | The path for Prometheus to pull metrics from Promxy. Note: the default path, "/metrics", is shadowed by ReverseProxy | `"/promxy/metrics"`
`promxy.headlessServiceName` | The name of headless service that is used for promxy to connect to PM Server targets directly. Defaults to "server" for backwards compatibility reasons during upgrade, but a more meaningful name can be set for new deployments | `"server"`
`promxy.replicaCount` | Number of promxy pods | `2`
`promxy.serviceAccountName` | If not given, RBAC & service account will be created for promxy when dynamic discovery is enabled; this is needed for promxy to perform the discovery to get all prometheus targets. "default" serviceaccount will be used when dynamic discovery is disabled. | `""`
`rbac.appMonitoring.configFileCreate`| Create Config file from ConfigMap template for Application Monitoring. | `true`
`rbac.appMonitoring.enabled`| Enables RBAC for single Application Monitoring. | `false`
`resources.eric-pm-configmap-reload.limits.cpu`| The maximum amount of CPU allowed per instance for configmapReload. | `200m`
`resources.eric-pm-configmap-reload.limits.memory`| The maximum amount of memory allowed per instance for configmapReload. | `32Mi`
`resources.eric-pm-configmap-reload.limits.ephemeral-storage`| The maximum amount of ephemeral-storage allowed per instance for configmapReload. | `""`
`resources.eric-pm-configmap-reload.requests.cpu`| The requested amount of CPU per instance for configmapReload. | `100m`
`resources.eric-pm-configmap-reload.requests.memory`| The requested amount of memory per instance for configmapReload. | `8Mi`
`resources.eric-pm-configmap-reload.requests.ephemeral-storage`| The requested amount of ephemeral-storage per instance for configmapReload. | `""`
`resources.eric-pm-exporter.limits.cpu`| The maximum amount of CPU allowed per instance for eric-pm-exporter. | `200m`
`resources.eric-pm-exporter.limits.memory`| The maximum amount of memory allowed per instance for eric-pm-exporter. | `32Mi`
`resources.eric-pm-exporter.limits.ephemeral-storage`| The maximum amount of ephemeral-storage allowed per instance for eric-pm-exporter. | `""`
`resources.eric-pm-exporter.requests.cpu`| The requested amount of CPU per instance for eric-pm-exporter. | `100m`
`resources.eric-pm-exporter.requests.memory`| The requested amount of memory per instance for eric-pm-exporter. | `8Mi`
`resources.eric-pm-exporter.requests.ephemeral-storage`| The requested amount of ephemeral-storage per instance for eric-pm-exporter. | `""`
`resources.eric-pm-initcontainer.limits.cpu` | The maximum amount of CPU allowed per instance for eric-pm-initcontainer. | `1`
`resources.eric-pm-initcontainer.limits.memory` | The maximum amount of memory allowed per instance for eric-pm-initcontainer. | `200Mi`
`resources.eric-pm-initcontainer.limits.ephemeral-storage` | The maximum amount of ephemeral-storage allowed per instance for eric-pm-initcontainer | `""`
`resources.eric-pm-initcontainer.requests.cpu` | The requested amount of CPU per instance for eric-pm-initcontainer. | `50m`
`resources.eric-pm-initcontainer.requests.memory` | The requested amount of memory per instance for eric-pm-initcontainer. | `50Mi`
`resources.eric-pm-initcontainer.requests.ephemeral-storage` | The requested amount of ephemeral-storage per instance for eric-pm-initcontainer. | `""`
`resources.eric-pm-reverseproxy.limits.cpu`| The maximum amount of CPU allowed per instance for reverseProxy. | `2`
`resources.eric-pm-reverseproxy.limits.memory`| The maximum amount of memory allowed per instance for reverseProxy. | `64Mi`
`resources.eric-pm-reverseproxy.limits.ephemeral-storage`| The maximum amount of ephemeral-storage allowed per instance for eric-pm-reverseproxy. | `""`
`resources.eric-pm-reverseproxy.requests.cpu`| The requested amount of CPU per instance for reverseProxy. | `100m`
`resources.eric-pm-reverseproxy.requests.memory`| The requested amount of memory per instance for reverseProxy. | `32Mi`
`resources.eric-pm-reverseproxy.requests.ephemeral-storage`| The requested amount of ephemeral-storage per instance for eric-pm-reverseproxy. | `""`
`resources.eric-pm-server.limits.cpu`| The maximum amount of CPU allowed per instance for the PM Service. | `2`
`resources.eric-pm-server.limits.memory`| The maximum amount of memory allowed per instance for the PM Service. | `2048Mi`
`resources.eric-pm-server.limits.ephemeral-storage`| The maximum amount of ephemeral-storage allowed per instance for the PM Service. | `8Gi`
`resources.eric-pm-server.requests.cpu`| The requested amount of CPU per instance for the PM Service. | `250m`
`resources.eric-pm-server.requests.memory`| The requested amount of memory per instance for the PM Service.| `512Mi`
`resources.eric-pm-server.requests.ephemeral-storage`| The requested amount of ephemeral-storage per instance for the PM Service.| `512Mi`
`resources.ericsecoauthsap.limits.cpu` | Maximum amount of CPU allowed per instance for the APO2 SAP init container | `50m`
`resources.ericsecoauthsap.limits.memory` | Maximum amount of memory allowed per instance for the APO2 SAP init container | `130Mi`
`resources.ericsecoauthsap.limits.ephemeral-storage` | Maximum amount of ephemeral-storage allowed per instance for APO2 SAP init container |
`resources.ericsecoauthsap.requests.cpu` | Requested amount of CPU per instance for the APO2 SAP init container | `50m`
`resources.ericsecoauthsap.requests.memory` | Requested amount of memory per instance for the APO2 SAP init container | `130Mi`
`resources.ericsecoauthsap.requests.ephemeral-storage` | Requested amount of ephemeral-storage allowed per instance for the APO2 SAP init container |
`resources.ericsecoauthproxy.limits.cpu` | Maximum amount of CPU allowed per instance for the Authorization proxy sidecar | `150m`
`resources.ericsecoauthproxy.limits.memory` | Maximum amount of memory allowed per instance for the Authorization proxy sidecar | `256Mi`
`resources.ericsecoauthproxy.limits.ephemeral-storage` | Maximum amount of ephemeral-storage allowed per instance for the Authorization proxy sidecar |
`resources.ericsecoauthproxy.requests.cpu` | Requested amount of CPU per instance for the Authorization proxy sidecar | `50m`
`resources.ericsecoauthproxy.requests.memory` | Requested amount of memory per instance for the Authorization proxy sidecar | `130Mi`
`resources.ericsecoauthproxy.requests.ephemeral-storage` | Requested amount of ephemeral-storage allowed per instance for the Authorization proxy sidecar |
`resources.hooklauncher.limits.cpu` | The maximum amount of CPU allowed per instance for hooklauncher. | `50m`
`resources.hooklauncher.limits.memory` | The maximum amount of memory allowed per instance for hooklauncher. | `100Mi`
`resources.hooklauncher.limits.ephemeral-storage` | Amount of local storage being limit for this container. | `100Mi`
`resources.hooklauncher.requests.cpu` | The requested amount of CPU per instance for hooklauncher. | `20m`
`resources.hooklauncher.requests.memory` | The requested amount of memory per instance for hooklauncher. | `50Mi`
`resources.hooklauncher.requests.ephemeral-storage` | Amount of local storage requested for this container. | `100Mi`
`resources.logshipper.limits.cpu`| The maximum amount of CPU allowed per instance for logshipper. | `100m`
`resources.logshipper.limits.memory`| The maximum amount of memory allowed per instance for logshipper. | `100Mi`
`resources.logshipper.limits.ephemeral-storage`| The maximum amount of ephemeral-storage allowed per instance for logshipper. | `""`
`resources.logshipper.requests.cpu`| The requested amount of CPU per instance for logshipper. | `50m`
`resources.logshipper.requests.memory`| The requested amount of memory per instance for logshipper. | `50Mi`
`resources.logshipper.requests.ephemeral-storage`| The requested amount of ephemeral-storage per instance for logshipper. | `""`
`resources.promxy.requests.memory` | The requested amount of memory per instance for the PM Promxy. | `512Mi`
`resources.promxy.requests.cpu` | The requested amount of CPU per instance for the PM Promxy. | `100m`
`resources.promxy.requests.ephemeral-storage` | The requested amount of ephemeral-storage per instance for the PM Promxy. | `""`
`resources.promxy.limits.memory` | The maximum amount of memory allowed per instance for the PM Promxy | `2048Mi`
`resources.promxy.limits.cpu` | The maximum amount of CPU allowed per instance for the PM Promxy. | `2`
`resources.promxy.limits.ephemeral-storage` | The requested amount of ephemeral-storage per instance for PM Promxy. | `""`
`scrapeConfig.global.scrapeInterval` | Configure the global default scrape interval for targets. | 15s |
`scrapeConfig.global.scrapeTimeout` | Configure the global default scrape timeout for targets. | 10s |
`scrapeConfig.global.evaluationInterval` | How frequently to evaluate rules | 1m |
`scrapeConfig.deprecatedJobs.selfMonitoring.enabled` | Enable deprecated self-monitoring static jobs for backward compatibility reasons. This parameter will be deprecated and removed in the future. | true |
`scrapeConfig.deprecatedJobs.appMonitoring.enabled` | Enable deprecated jobs for backward compatibility reasons. This parameter will be deprecated and removed in the future. | true |
`scrapeConfig.jobs.deprecatedLabels.enabled` | Enable deprecated job labels in all jobs for backward compatibility reasons. This parameter will be deprecated and removed in the future. | true
`scrapeConfig.jobs.pod.scrape15s.enabled` | Enable scrape jobs with pod role type and 15-second scrape interval | true |
`scrapeConfig.jobs.pod.scrape15s.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 15-second scraping interval | 5 |
`scrapeConfig.jobs.pod.scrape1m.enabled` | Enable scrape jobs with endpoints role type and 01-minute scrape interval | false |
`scrapeConfig.jobs.pod.scrape1m.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 1-minute scraping interval | 5 |
`scrapeConfig.jobs.pod.scrape3s.enabled` | Enable scrape jobs with pod role type and 03-second scrape interval | false |
`scrapeConfig.jobs.pod.scrape3s.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 3-second scraping interval | 5 |
`scrapeConfig.jobs.pod.scrape5m.enabled` | Enable scrape jobs with pod role type and 05-minute scrape interval | false |
`scrapeConfig.jobs.pod.scrape5m.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 5-minute scraping interval | 5 |
`scrapeConfig.jobs.service.scrape15s.enabled` | Enable scrape jobs with service role type and 15-second scrape interval | true |
`scrapeConfig.jobs.service.scrape15s.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 15-second scraping interval | 5 |
`scrapeConfig.jobs.service.scrape1m.enabled` | Enable scrape jobs with service role type and 1-minute scrape interval | false |
`scrapeConfig.jobs.service.scrape1m.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 1-minute scraping interval | 5 |
`scrapeConfig.jobs.service.scrape3s.enabled` | Enable scrape jobs with service role type and 3-second scrape interval | false |
`scrapeConfig.jobs.service.scrape3s.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 3-second scraping interval | 5 |
`scrapeConfig.jobs.service.scrape5m.enabled` | Enable scrape jobs with service role type and 5-minute scrape interval | false |
`scrapeConfig.jobs.service.scrape5m.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 5-minute scraping interval | 5 |
`scrapeConfig.jobs.endpoints.scrape15s.enabled` | Enable scrape jobs with endpoints role type and 15-second scrape interval | true |
`scrapeConfig.jobs.endpoints.scrape15s.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 15-second scraping interval | 5 |
`scrapeConfig.jobs.endpoints.scrape1m.enabled` | Enable scrape jobs with endpoints role type and 1-minute scrape interval | false |
`scrapeConfig.jobs.endpoints.scrape1m.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 1-minute scraping interval  | 5 |
`scrapeConfig.jobs.endpoints.scrape3s.enabled` | Enable scrape jobs with endpoints role type and 3-second scrape interval | false |
`scrapeConfig.jobs.endpoints.scrape3s.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 3-second scraping interval | 5 |
`scrapeConfig.jobs.endpoints.scrape5m.enabled` | Enable scrape jobs with endpoints role type and 5-minute scrape interval | false |
`scrapeConfig.jobs.endpoints.scrape5m.metricsPathCount` | The total number of metric paths supported for scrape jobs with a 5-minute scraping interval | 5 |
`securityContext`| Security Context for all containers. | `{}`
`securityPolicy.eric-pm-server.rolename`| The attribute sets the name of the security policy role that is bound to the PM Server service account. **_Note:_** This attribute is only valid if rbac.appMonitoring is enabled. | `"eric-pm-server"`
`securityPolicy.eric-pm-server-promxy.rolename`| The attribute sets the name of the security policy role that is bound to the PM Promxy pod service account. **_Note:_** DO NOT USE 'eric-pm-server-promxy', or '{.Value.nameOverride}-promxy' if nameOverride is specified, which is dedicated to Promxy dynamic discovery. This attribute is only valid if promxy.dynamicDiscovery is enabled. | `"eric-pm-server-promxy-sp"`
`securityPolicy.hooklauncher.rolename`| The attribute sets the name of the security policy role that is bound to the Hooklauncher pod service account. | `"eric-lcm-smart-helm-hooks"`
`seccompProfile.eric-pm-configmap-reload.localhostProfile`| The 'Localhost' seccomp profile requires a profile name to be provided. The name of the local seccomp profile to be used for eric-pm-configmap-reload.| `""`
`seccompProfile.eric-pm-configmap-reload.type`| Configuration of seccomp profile type for eric-pm-configmap-reload. It overrides pod level configuration.| `""`
`seccompProfile.eric-pm-exporter.localhostProfile`| The 'Localhost' seccomp profile requires a profile name to be provided. The name of the local seccomp profile to be used for eric-pm-exporter.| `""`
`seccompProfile.eric-pm-exporter.type`| Configuration of seccomp profile type for eric-pm-exporter. It overrides pod level configuration.| `""`
`seccompProfile.eric-pm-reverseproxy.localhostProfile`| The 'Localhost' seccomp profile requires a profile name to be provided. The name of the local seccomp profile to be used for eric-pm-reverseproxy.| `""`
`seccompProfile.eric-pm-reverseproxy.type`| Configuration of seccomp profile type for eric-pm-reverseproxy. It overrides pod level configuration.| `""`
`seccompProfile.eric-pm-server.localhostProfile`| The 'Localhost' seccomp profile requires a profile name to be provided. The name of the local seccomp profile to be used for eric-pm-server.| `""`
`seccompProfile.eric-pm-server.type`| Configuration of seccomp profile type for eric-pm-server. It overrides pod level configuration.| `""`
`seccompProfile.ericsecoauthsap.localhostProfile` | The 'localhost' profile name for the ericsecoauthsap container if type is Localhost | `commented out`
`seccompProfile.ericsecoauthsap.type` | Configuration of seccomp type for ericsecoauthsap container ("Unconfined", "RuntimeDefault", "Localhost", "") | `commented out`
`seccompProfile.ericsecoauthproxy.localhostProfile` | The 'localhost' profile name for the ericsecoauthproxy container if type is 'localhost' | `commented out`
`seccompProfile.ericsecoauthproxy.type` | Configuration of seccomp type for ericsecoauthproxy container ("Unconfined", "RuntimeDefault", "Localhost", "") | `commented out`
`seccompProfile.logshipper.localhostProfile`| The 'Localhost' seccomp profile requires a profile name to be provided. The name of the local seccomp profile to be used for logshipper.| `""`
`seccompProfile.logshipper.type`| Configuration of seccomp profile type for logshipper. It overrides pod level configuration.| `""`
`seccompProfile.localhostProfile`| The 'Localhost' seccomp profile requires a profile name to be provided. The name of the local seccomp profile to be used for pod.| `""`
`seccompProfile.type`| Configuration of seccomp profile type for pod. The setting applies to all container when the container specific parameter is omitted.| `""`
`server.baseURL`| The external url at which the server can be accessed. | `""`
`server.configMapOverrideName`| PM Server ConfigMap override where full-name is `{{.Values.server.configMapOverrideName}}` and setting this value will prevent the default server ConfigMap from being generated. | `""`
`server.extraArgs`| Additional PM Server container arguments. **_Note:_** `server.extraArgs.storage.tsdb.retention.time` and `server.extraArgs.storage.tsdb.retention.size` will be removed in the near future. | `{}`
`server.extraHostPathMounts`| Additional PM Server hostPath mounts. | `[]`
`server.extraEmptyDirVolumeMounts`| Additional PM Server emptyDir mounts. | `[]`
`server.extraSecretMounts`| Additional PM Server secret mounts. | `[]`
`server.extraConfigmapMounts`| Additional PM Server configmap mounts(for rules), an alpha feature. | `[]`
`serverFiles.prometheus.yml` | PM Server scrape configuration. | `Kubernetes SD Endpoints`
`server.ha.enabled` | Alpha Feature to enable High Availability and Query Proxy | `false`
`server.name`| PM Server container name. | `server`
`server.nodeSelector`| To be deprecated soon. Node labels for Prometheus server pod assignment. | `{}`
`server.persistentVolume.accessModes`| PM Server data Persistent Volume access modes. | `[ReadWriteOnce]`
`server.persistentVolume.annotations` | PM Server data Persistent Volume annotations. | `{}`
`server.persistentVolume.enabled`| If true, PM Server will create a Persistent Volume Claim. If set to false, with POD restarts & helm upgrades PM data will be erased/wiped off. | `false`
`server.persistentVolume.mountPath`| PM Server data Persistent Volume mount root path. | `/data`
`server.persistentVolume.size`| PM Server data Persistent Volume size. | `8Gi`
`server.persistentVolume.storageClass` | PM Server data Persistent Volume Storage Class | `commented out`
`server.persistentVolume.storageConnectivity` | The connectivity of the storage, either local or networked. | `networked`
`server.persistentVolume.subPath`| Subdirectory of PM Server data Persistent Volume to mount. | `""`
`server.podAnnotations` | Annotations to be added to PM Server pods. | `{}`
`server.prefixURL`| The prefix url at which the server can be accessed. | `""`
`server.replicaCount`| Desired number of PM Server pods. | `1`
`server.retention` | Determine how long data will be kept on the persistent volume. A time duration can be specified in different units where the most useful in in this case are(h)ours, (d)ays or (w)eeks. The prometheus default is 15d. **_Note:_** This parameter will be deprecated. Please use `server.tsdb.retention.time` instead. | `""`
`server.tsdb.retention.time`| Determine how long data will be kept on the persistent volume. A time duration can be specified in different units where the most useful in in this case are (h)ours, (d)ays or (w)eeks. The prometheus default is 15d. **_Note:_** `server.tsdb.retention.time` takes precedence over `server.extraArgs.storage.tsdb.retention.time` and `server.retention`. | `""`
`server.tsdb.retention.size`| Determine the maximum number of bytes of storage blocks to retain. Units supported: B, KB, MB, GB, TB, PB, EB. Defaults to 0 or disabled. **_Note:_** `server.tsdb.retention.size` takes precedence over `server.extraArgs.storage.tsdb.retention.size`. | `""`
`server.serviceAccountName`| Service account name for server to use. | `default`
`server.service.annotations` | Annotations for PM Server service. | `{}`
`server.service.httpPort`| The PM Server port for clear-text based query traffic. | `9090`
`server.service.httpsPort`| The PM Server port for TLS based query traffic. | `9089`
`server.service.labels` | Labels for PM Server service. | `{}`
`server.service.servicePort` | Service Port | ``
`server.tolerations`| Node taints to tolerate (requires Kubernetes >=1.6). | `[]`
`service.endpoints.authorizationProxy.tls.enforced` | Use HTTPS for Authorization Proxy with `required` and HTTP with `optional`. Only one at a time is supported | `required`
`service.endpoints.authorizationProxy.tls.verifyClientCertificate` | Whether Authorization Proxy server verifies the client certificates sent by ICCR. Only effective if `service.endpoints.authorizationProxy.tls.enforced` is required. See `clientCertificate.enabled` in [Ingress Controller CR documentation][ICCR] | `required`
`service.endpoints.reverseproxy.readWriteTimeout`| This parameter sets the connection timeout between reverseproxy and Prometheus.  For long queries, this parameter should be increased.  Check user guide for further information. | `300`
`service.endpoints.reverseproxy.tls.enforced`| The option controls if cleartext and TLS or only TLS is allowed on the PM query interface. Value optional allows both cleartext and TLS. Value required allows only TLS. | `required`
`service.endpoints.reverseproxy.tls.verifyClientCertificate` | It checks whether the client connection toward PM's reverseproxy using TLS requires authentication or not.  Non-authenticated connections will be logged and dropped in case this is enforced as required, otherwise the connection establishment will be granted. By default it is required, otherwise set it as optional. | `required`
`service.endpoints.reverseproxy.tls.certificateAuthorityBackwardCompatibility` | If true, SIP-TLS as CA will be used for query interface. | `false`
`service.endpoints.scrapeTargets.tls.enforced`| This options applies to the default server ConfigMap for application monitoring. The option controls if both cleartext and TLS scrape targets or only TLS scrape targets will be considered for service discovery. Value optional will allow scraping of both cleartext and TLS targets. Value required will restrict scraping to TLS targets only. | `required`
`terminationGracePeriodSeconds.promxy` | PM Promxy pod termination grace period. | `300`
`terminationGracePeriodSeconds.server` | PM Server Pod termination grace period. | `300`
`tolerations.eric-pm-server`| The toleration specification for the PM Server pod. If both `tolerations.eric-pm-server` and ``server.tolerations` are set, the values set for `tolerations.eric-pm-server` are used. | `[]`
`tolerations.eric-pm-server-promxy` | The toleration specification for the PM Server Promxy pod. `[]`
`tolerations.hooklauncher` | The toleration specification for the Smart Helm Hook pod(s)) `[]`
`topologySpreadConstraints` | TopologySpreadConstraint can be specified to spread PM Server pods among the given topology to achieve high availability and efficient resource utilization.Application deployment engineer can define one or multiple topologySpreadConstraint. This parameter is being deprecated, please use topologySpreadConstraints.eric-pm-server | `[]`
`topologySpreadConstraints.eric-pm-server` | TopologySpreadConstraint can be specified to spread PM Server pods among the given topology to achieve high availability and efficient resource utilization. Application deployment engineer can define one or multiple topologySpreadConstraint. | `[]`
`updateStrategy.promxy.rollingUpdate.maxSurge` | maxSurge number of pods when update. | `50%`
`updateStrategy.promxy.rollingUpdate.maxUnavailable` | maxUnavailable number of pods when update. | `50%`
`updateStrategy.promxy.type` | PM Promxy updateStrategy. | `{type: RollingUpdate}`
`updateStrategy.server.type` | PM Server updateStrategy. | `{type: RollingUpdate}`

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install ./eric-pm-server --name my-release \
    --set terminationGracePeriodSeconds.server=360
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install ./eric-pm-server --name my-release -f values.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)

### ConfigMap Files
PM Server is configured through prometheus.yml. This file (and any others listed in `serverFiles`) will be mounted into the `server` pod.

### Enabling RBAC for Service Accounts
PM server needs proper access rights in the Kubernetes cluster to be able to scrape all the PM providers listed in the configuration file.
Below are the steps to achive this with cluster role, service account and cluster role binding.

1. Create a ClusterRole to monitor

Here is an example:

```
$ cat server-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
  name: "eric-pm-server-staging"
rules:
  - apiGroups:
      - ""
    resources:
      - nodes
      - nodes/proxy
      - services
      - endpoints
      - pods
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - get
  - apiGroups:
      - "extensions"
    resources:
      - ingresses/status
      - ingresses
    verbs:
      - get
      - list
      - watch
  - nonResourceURLs:
      - "/metrics"
    verbs:
      - get
```

```
$ kubectl  apply -f server-clusterrole.yaml
clusterrole "eric-pm-server-staging" configured
```
2. Create a Service Account

Below is an example of creating a service account named "monitoring" in the namespace "staging".
```
$ kubectl create sa monitoring --namespace staging
serviceaccount "monitoring" created
```
> **Tip** One must deploy the PM server in the same namespace in which the service account is created.
So in this case PM server should be deployed in staging namespace.

3. Create a ClusterRoleBinding

Below is an example of creating a cluster role binding named "eric-pm-server-staging" connecting the
cluster role "eric-pm-server-staging" with service account "monitoring" in the namespace "staging".
```
$ kubectl create clusterrolebinding eric-pm-server-staging \
  --clusterrole=eric-pm-server-staging --serviceaccount=staging:monitoring
clusterrolebinding "eric-pm-server-staging" created
```

### How to configure Pod Priority Class parameter
The priorityClassName needs to refer to an already existing priority class, otherwise the pod(s) will be rejected. With the default value of an empty string, no priorityClass will be specified and the pod(s) will be assigned the default pod priority class.
