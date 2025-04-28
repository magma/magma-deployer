MAGMA_ROOT=/home/jblake1/build/magma
TAG=local
TAG=$(git branch|grep '*'|awk '{print $2}'|cut -c1-7)
echo TAG=$TAG
DOCKER_BUILDKIT=1 docker build -t local/agw_gateway_c:${TAG} -f services/c/Dockerfile $MAGMA_ROOT
# DOCKER_BUILDKIT=1 docker build --no-cache -t local/agw_gateway_c:${TAG} -f services/c/Dockerfile $MAGMA_ROOT

