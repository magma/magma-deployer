#!/bin/bash
CHARTPATH="../helm/charts/agwc"
cd ${CHARTPATH}
helm delete agwc -n magma && kubectl delete pvc agwc-claim -n magma &&  kubectl delete -f agwc-pv.yaml
