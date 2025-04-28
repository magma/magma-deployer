MAGMA_ROOT=/home/jblake1/build/magma
TAG=local
TAG=$(git branch|grep '*'|awk '{print $2}'|cut -c1-7)
echo TAG=$TAG
# DOCKER_BUILDKIT=1 docker build --no-cache --build-arg CPU_ARCH=aarch64 --build-arg DEB_PORT=arm64 -t local/agw_gateway_python_arm:$TAG -f services/python/Dockerfile $MAGMA_ROOT
DOCKER_BUILDKIT=1 docker build -t local/agw_gateway_python:$TAG -f services/python/Dockerfile $MAGMA_ROOT
