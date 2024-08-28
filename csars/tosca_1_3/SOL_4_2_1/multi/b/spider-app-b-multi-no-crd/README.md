Note:

This CSAR can be used to cover the positive testing scenarios of an upgrade from a package with levels (spider-app-multi-a-etsi-tosca-rel4 should be 
used for 
the initial package).

Levels:  
- instantiation_level_1 is available in this package, if a is instantiated with that level, it should be persisted upon upgrade.
- instantiation_level_2 is also available in both packages but references different aspects.
- instantiation_level_3 is only available in this package and is the default level. By instantiating using level_1 and upgrading to this package,
  we can show the default level of the target package is overwritten correctly.

The scaling_mapping file allows the user to map between the autoscaling and replica details required for each helm chart (spider-app or 
test-scale-chart)

Autoscaling will only impact charts with hpa defined. This is test-cnf-vnfc1, which is referenced in Aspect4 only. To test this hpa capability, 
the extension for Aspect4 should be set to CISMControlled. 
