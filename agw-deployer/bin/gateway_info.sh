export MPOD=$(kubectl get pods -n magma| grep magmad|awk '{print $1}') ; echo $MPOD
kubectl exec -it -n magma $MPOD -- show_gateway_info.py
