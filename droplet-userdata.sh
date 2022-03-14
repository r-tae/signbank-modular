#!/bin/bash
set -euo pipefail

USERNAME=user # TODO: rename this

# TODO: check if we can expire password without causing the deploys to
# fail complaining about not being able to reset password without a TTY
# Create user and immediately expire password to force a change on login
useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"
# passwd --delete "${USERNAME}"
# chage --lastday 0 "${USERNAME}"

groupadd docker
usermod -aG docker "${USERNAME}"


# Create SSH directory for sudo user and move keys over
home_directory="$(eval echo ~${USERNAME})"
mkdir --parents "${home_directory}/.ssh"
cp /root/.ssh/authorized_keys "${home_directory}/.ssh"
chmod 0700 "${home_directory}/.ssh"
chmod 0600 "${home_directory}/.ssh/authorized_keys"
chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"

# Disable root SSH login with password
sed --in-place 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
if sshd -t -q; then systemctl restart sshd; fi

# Install docker
snap install docker
apt install -y nginx-light

sudo systemctl start docker
