cd ~/magma-deployer/rke
rke remove
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
