#!/bin/bash
# Copyright 2021 The Magma Authors.

# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

MODE=$1
RERUN=0    # Set to 1 to skip network configuration and run ansible playbook only
WHOAMI=$(whoami)
MAGMA_USER="ubuntu"
MAGMA_VERSION="${MAGMA_VERSION:-v1.9}"
GIT_URL="${GIT_URL:-https://github.com/magma/magma.git}"
DEPLOY_PATH="/opt/magma/lte/gateway/deploy"

if [ $RERUN -eq 0 ]; then
  # Update DNS resolvers
  ln -sf /var/run/systemd/resolve/resolv.conf /etc/resolv.conf
  sed -i 's/#DNS=/DNS=8.8.8.8 208.67.222.222/' /etc/systemd/resolved.conf
  service systemd-resolved restart

  # echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#  cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
#  APT::Periodic::Update-Package-Lists "0";
#  APT::Periodic::Download-Upgradeable-Packages "0";
#  APT::Periodic::AutocleanInterval "0";
#  APT::Periodic::Unattended-Upgrade "0";
# EOF

  apt purge --auto-remove unattended-upgrades -y
  apt-mark hold "$(uname -r)" linux-aws linux-headers-aws linux-image-aws

  # interface config
  INTERFACE_DIR="/etc/network/interfaces.d"
  mkdir -p "$INTERFACE_DIR"
  echo "source-directory $INTERFACE_DIR" > /etc/network/interfaces

  # get rid of netplan
  # systemctl unmask networking
  # systemctl enable networking

  echo "Install Magma"

  echo "Making sure $MAGMA_USER user is sudoers"
  if ! grep -q "$MAGMA_USER ALL=(ALL) NOPASSWD:ALL" /etc/sudoers; then
    adduser --disabled-password --gecos "" $MAGMA_USER
    adduser $MAGMA_USER sudo
    echo "$MAGMA_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

    adduser $MAGMA_USER docker
  fi

  alias python=python3

  rm -rf /opt/magma/
  git clone "${GIT_URL}" /opt/magma
  cd /opt/magma || exit
  git checkout "$MAGMA_VERSION"

  # changing intefaces name
#  sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"/g' /etc/default/grub
#  update-grub2

fi

echo "Generating localhost hostfile for Ansible"
echo "[agw_docker]
127.0.0.1 ansible_connection=local" > $DEPLOY_PATH/agw_hosts

if [ "$MODE" == "base" ]; then
  su - $MAGMA_USER -c "sudo ansible-playbook -v -e \"MAGMA_ROOT='/opt/magma' OUTPUT_DIR='/tmp'\" -i $DEPLOY_PATH/agw_hosts --tags base $DEPLOY_PATH/magma_docker.yml"
else
  # install magma and its dependencies including OVS.
  su - $MAGMA_USER -c "sudo ansible-playbook -v -e \"MAGMA_ROOT='/opt/magma' OUTPUT_DIR='/tmp'\" -i $DEPLOY_PATH/agw_hosts --tags agwc $DEPLOY_PATH/magma_docker.yml"
fi

[[ $RERUN -eq 1 ]] || echo "Reboot this VM to apply kernel settings"
