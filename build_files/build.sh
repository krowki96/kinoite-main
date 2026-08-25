#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# Disable multimedia repo
for repo in /etc/yum.repos.d/*multimedia*.repo; do \
    [ -f "$repo" ] && sed -i 's/^enabled=1/enabled=0/' "$repo"; \
done

# Install RPM Fusion repo
dnf5 install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \

# Install NVIDIA 580.xx driver akmod for legacy Pascal cards, and build requirements
dnf5 install -y \
    akmod-nvidia-580xx \
    xorg-x11-drv-nvidia-580xx \
    xorg-x11-drv-nvidia-580xx-cuda \
    kernel-devel \
    kernel-headers \
    gcc \
    make \
    elfutils-libelf-devel \
    kmodtool \
    mokutil

# Compile driver for this build's kernel
kver="$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core | tail -n1)"; \
    akmods --force --kernels "$kver"; \
    depmod -a "$kver"

# this installs a package from fedora repos
dnf5 install -y tmux steam

dnf5 clean all

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
