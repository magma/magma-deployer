MPOD=$(kubectl get pods -n magma| grep oai-mme|awk {print }) ; echo $MPOD
