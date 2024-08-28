#!/usr/bin/env bash

#===========  SOL-2.5.1 Basic single   =====================

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/basic/basic-app-a/basic-app-a.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/basic/basic-app-b/basic-app-b.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/basic/basic-app-c/basic-app-c.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

#===========   SOL-2.5.1 single   =====================

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/single/spider-app-c-single/spider-app-c.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/single/spider-app-a-single/spider-app-a-single-v2.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/single/spider-app-a-single/spider-app-a.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/single/spider-app-b-single/spider-app-b.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/single/spider-app-levels-no-mapping/spider-app-levels-no-mapping.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/single/spider-app-levels-with-mapping/spider-app-levels-with-mapping.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/single/spider-app-same-chart-single/spider-app-lightweight-same-chart-1.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/single/spider-app-same-chart-single/spider-app-lightweight-same-chart-2.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

#===========   SOL-2.5.1 multi   =====================

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-a-multi/spider-app-multi-a-v2.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-a-multi/spider-app-multi-a-v2-dm.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-a-multi/spider-app-multi-a-v2-up.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-a-multi/spider-app-multi-a-full-stack.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-a-multi/spider-app-multi-a-v2-no-crd.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-b-multi/spider-app-multi-b-v2.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-b-multi/spider-app-multi-b-v2-dm.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-b-multi/spider-app-multi-b-v2-up.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-b-multi/spider-app-multi-b-full-stack.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_2/SOL_2_5_1/multi/spider-app-b-multi/spider-app-multi-b-v2-no-crd.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

#===========   SOL-3.3.1 single   =====================

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_3_3_1/single/spider-app-b-single/spider-app-b-tosca.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_3_3_1/single/spider-app-c-single/spider-app-c-tosca.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

#===========   SOL-3.3.1 multi   =====================

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_3_3_1/multi/spider-app-a-multi/spider-app-multi-a-tosca.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_3_3_1/multi/spider-app-a-multi/spider-app-multi-a-tosca-dm.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_3_3_1/multi/spider-app-a-multi/spider-app-multi-a-tosca-up.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_3_3_1/multi/spider-app-b-multi/spider-app-multi-b-tosca.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_3_3_1/multi/spider-app-b-multi/spider-app-multi-b-tosca-dm.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_3_3_1/multi/spider-app-b-multi/spider-app-multi-b-tosca-onboard.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_3_3_1/multi/spider-app-b-multi/spider-app-multi-b-tosca-up.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

#===========   SOL-4.2.1 single   =====================

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/single/spider-app-b-single/spider-app-b-etsi-tosca-rel4.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/single/spider-app-c-single/spider-app-c-etsi-tosca-rel4.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

#===========   SOL-4.2.1 multi   =====================

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-only-scalable-vdus/spider-app-multi-a-etsi-tosca-rel4.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-only-scalable-vdus/spider-app-multi-a-rel4-dm.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-only-scalable-vdus/spider-app-multi-a-etsi-tosca-rel4-cmpv2-enrollment.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-only-scalable-vdus/spider-app-multi-a-etsi-tosca-rel4-up.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-only-scalable-vdus/spider-app-multi-a-nrm-750-pods.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-only-non-scalable-vdus/spider-app-multi-a-etsi-tosca-all-non-scalable-vdus-rel4.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-only-non-scalable-vdus/spider-app-multi-a-rel4-dm-non-scalable.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-mixed-vdus/spider-app-multi-a-etsi-tosca-mixed-vdu-rel4.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-mixed-vdus/spider-app-multi-a-rel4-dm-mixed-vdu.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-max-complexity/spider-app-multi-a-etsi-tosca-rel4-max-complexity.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/a/spider-app-a-multi-no-crd/spider-app-multi-a-etsi-tosca-rel4-no-crd.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-only-scalable-vdus/spider-app-multi-b-etsi-tosca-rel4.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-only-scalable-vdus/spider-app-multi-b-rel4-dm.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-only-scalable-vdus/spider-app-multi-b-etsi-tosca-rel4-up.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-only-scalable-vdus/spider-app-multi-b-nrm-750-pods.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-only-non-scalable-vdus/spider-app-multi-b-etsi-tosca-all-non-scalable-vdus-rel4.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-only-non-scalable-vdus/spider-app-multi-b-rel4-dm-non-scalable.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-mixed-vdus/spider-app-multi-b-etsi-tosca-mixed-vdu-rel4.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-mixed-vdus/spider-app-multi-b-rel4-dm-mixed-vdu.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-max-complexity/spider-app-multi-b-etsi-tosca-rel4-max-complexity.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP

scripts/package_csar.py build \
--vnfd-path=csars/tosca_1_3/SOL_4_2_1/multi/b/spider-app-b-multi-no-crd/spider-app-multi-b-etsi-tosca-rel4-no-crd.yaml \
--no-images \
--login=amadm100 \
--password=3Af3daHihNurm*yP
