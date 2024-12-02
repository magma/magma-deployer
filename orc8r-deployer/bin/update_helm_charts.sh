export GITHUB_REPO=magma-charts
export GITHUB_REPO_URL=https://github.com
export GITHUB_USERNAME=jblakley
export MAGMA_ROOT=~/magma
read -s -p "Enter Github Access Token: " GITHUB_ACCESS_TOKEN
export GITHUB_ACCESS_TOKEN
${MAGMA_ROOT}/orc8r/tools/helm/package.sh -d all

