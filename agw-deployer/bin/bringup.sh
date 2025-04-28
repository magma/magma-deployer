#!/bin/bash
CHARTPATH="../helm/charts/agwc"
cd ${CHARTPATH}
kubectl delete -f agwc-pv.yaml
kubectl apply -f agwc-pv.yaml;helm install agwc . --values=values.yaml -n magma
