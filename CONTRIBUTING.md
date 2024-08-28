# Contributing

When contributing to this repository, please first discuss the change you wish to make with one of "Honey" by [email]()  [Teams](https://teams.microsoft.com/l/team/19%3a262357938b3c4f9d807da7b13660541e%40thread.skype/conversations?groupId=1b28afdd-5adf-4d89-8aaa-3ca47f433ca4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) ,
email, or any other method before making a change.

## Process for updating CSARs content

### Testing Artifacts structure
- Packages are located in the directories according to tosca and SOL versions
- Single folder may contain multiple VNFDs - each VNFD represents package
- To build particular package --vnf-path have to be passed to the package_csar.py
- Each VNFD has its own Changelog file in the changelogs/ folder. Naming convention is - Changelog.<VNFD_NAME>.txt 
- The following files are common for all CSARs located in one directory:
  - properties.yaml
  - manifest.mf
  - scaling_mapping.yaml
- It's recommended to avoid creating of new CSAR folders, unless new package differs with the listed above files

### CSAR Build Instructions
- package_csar.py script is used for building packages:
  ```
  scripts/package_csar.py build --vnfd-path=csars/tosca_1_2/SOL_2_5_1/basic/basic-app-a/basic-app-a.yaml --login=<LOGIN> --password=<PASSWORD>
  ```
- By default package charts are downloaded from artifactory. Local charts are located in the charts/ directory.
- To build local charts before downloading from artifactory, use parameter --build-charts:
  ```
  scripts/package_csar.py build --vnfd-path=csars/tosca_1_2/SOL_2_5_1/basic/basic-app-a/basic-app-a.yaml --buid-charts --login=<LOGIN> --password=<PASSWORD>
  ```
  - When this parameter specified, script firstly looking for charts in the charts/ directory. 
  After that all charts that were not found locally are downloaded from artifactory.
  - NOTE: this parameter must be used for development purposes only
  - Package cannot be uploaded to Nexus, if --build-charts was specified to build a CSAR

### Uploading charts to Artifactory
- New charts are automatically uploaded to the Artifactory during CSARs uploading by job - https://fem4s11-eiffel052.eiffel.gic.ericsson.se:8443/jenkins/job/tools_Tests_CSAR/ 

- In case when need to add new chart to artifactory manually use script - upload_chart.py:
  ```
  scripts/upload_chart.py upload --chart-name=busybox-simple-chart-a --chart-version=1.0.0 --login=<LOGIN> --password=<PASSWORD>
  ```
- It packages chart and uploads to the Artifactory
- !!! IMPORTANT: USE THIS SCRIPT ONLY AFTER COMMIT WITH PACKAGE WAS REVIEWED AND MERGED

### CSAR Naming
- CSAR name is automatically set by package_csar.py based on the VNFD file name
- Name inside properties.yaml is the name of configuration, not CSAR package
- If you want to change package name - simply rename VNFD file
- For signed packages suffixes are automatically added to the name:
  - <VNFD_NAME>-option1
  - <VNFD_NAME>-option2
  - <VNFD_NAME>-option1-option2

### Before making changes :
- Prioritise amending existent CSAR files rather than creating new artifacts. This is to reduce maintenance required.

### Before posting review request :
- Increment versions
   - CSAR version in VNFD (node_types.descriptor_version and node_types.software_version)
   - Helm chart version if chart was changes
      - Update chart version in vnfd (node_types.artifacts.helm_package)
- Package CSAR with the latest package manager (with images and without) [package-manager README.md](https://gerrit.ericsson.se/plugins/gitiles/OSS/com.ericsson.orchestration.mgmt.packaging/am-package-manager/+/refs/heads/master/README.md)
   - CSAR package name should include CSAR version
- Ensure that CSAR can be on-boarded using the latest EVNFM version (with and without images)
- Ensure that life-cycle operations listed for this particular csar can be performed using the latest version of EVNFM

### Posting review request :
- Post review request to [Review Channel](https://teams.microsoft.com/l/channel/19%3a4f3933f0caf84630be751fc5022daef9%40thread.skype/Review%2520requests?groupId=1b28afdd-5adf-4d89-8aaa-3ca47f433ca4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f)

### After change was reviewed and submitted:
- Upload new CSARs to [Nexus](https://arm901-eiffel052.athtem.eei.ericsson.se:8443/nexus/#view-repositories;evnfm_testing_artifacts~browsestorage)
- Upload new CSARs to Jenkins [process engines](https://fem4s11-eiffel052.eiffel.gic.ericsson.se:8443/jenkins/computer/) if applicable
   - path to csars on process engines is /home/amadm100/release-testing-csars/
- Update path to CSAR in tests if updated CSAR(s) are used in any of our test automation suites.
  - update path to csar in tests config
     - [e2e integration](https://gerrit.ericsson.se/plugins/gitiles/OSS/com.ericsson.orchestration.mgmt/am-integration-charts/+/refs/heads/master/template.json)
- Update [EVNFM Testing CSARs](https://confluence-oss.seli.wh.rnd.internal.ericsson.com/display/ESO/EVNFM+Testing+CSARs) confluence page
- Update the following file in the am-ci-flow so that ansible script can be run to cleanup old images and to download newer images from nexus
```
am-ci-flow/infra/ansible/setup_jenkins_slaves/defaults/main.yaml
```

**Uploading a CSAR to Nexus**

1. Navigate to arm901
2. Login as amadm100
3. On the left sidebar choose Repositories from the Views/Repositories expandable
4. Choose 'EVNFM Testing Artifacts' from the list in the top panel
5. In the bottom panel click the 'Artifact Upload' tab
```
   GAV Definition: GAV Parameters
   Group: Depends on type of csar being uploaded - helm2 single csars should be 'helm2.single', helm3 multi csars should be 'helm3.multi' etc.
   Artifact: Name to upload file as
   Version: Appropriate version (e.g. 1.0.0 if new file or something like 1.0.4 if a new version of a file)
   Packaging: pom.xml
```
6. Choose file using the 'Select Artifact(s) to Upload...' button
```
   Filename: Will be autopopulated with a fakepath
   Classifier: Will be blank or auto-populated with 'imageless' if uploading an imageless csar or 'v2' if uploading a helm3 csar etc. If uploading 
               a v2 imageless csar, ensure to update the classifier to 'v2-imageless' as it will only auto-populate the 'imageless'.
   Extension: Will be csar for CSAR file for example
```
7. Click 'Add Artifact' button and file should show in Artifact window
8. Click 'Upload Artifact(s)' button to finalise upload
