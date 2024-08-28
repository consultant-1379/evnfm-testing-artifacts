$apm_version="2.8.0-1"
$path_to_root_mount="$pwd\\.."
$csar_dir="basic-app-b"
$csar_name="basic-app-b-1.0.0"
$chart_dir1="charts/busybox-simple-chart"
$charts_dir="packaged-charts"
$vnfd="basic-app-b.yaml"
$importedDescriptor="imports/etsi_nfv_sol001_vnfd_type_for_rollback_support.yaml"
$manifest="basic-app-b.mf"

Set-Location -Path "$path_to_root_mount\\$csar_name"
Remove-Item $charts_dir -Recurse -ErrorAction Ignore
helm package $chart_dir1
mkdir -p $charts_dir
mv *.tgz $charts_dir
docker run --rm -v ${path_to_root_mount}:/csar -v /var/run/docker.sock:/var/run/docker.sock -w /csar armdocker.rnd.ericsson.se/proj-am/releases/eric-am-package-manager:$apm_version generate -hd $csar_dir/$charts_dir --name $csar_name --vnfd $csar_dir/$vnfd -mf $csar_dir/$manifest -d $csar_dir/$importedDescriptor --helm3