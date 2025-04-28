#!/bin/bash
CHARTPATH="../helm/charts/agwc"
cd ${CHARTPATH}
helm install --debug --dry-run agwc . --values=values.yaml|less
