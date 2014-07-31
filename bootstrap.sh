#!/bin/bash

TIMEZONE="Europe/Stockholm"
export DEBIAN_FRONTEND=noninteractive
export PASSWORD=$(openssl rand -base64 32 | openssl md5 | awk '{print $2}')

chmod 7777 /id_rsa /id_rsa.pub /authorized_keys /id_rsa_plain_text

apt-get update
apt-get upgrade -y -q
apt-get dist-upgrade -y -q
apt-get -y -q autoclean
apt-get -y -q autoremove

add-apt-repository ppa:mizuno-as/silversearcher-ag -y

apt-get update

apt-get install --force-yes -y -q vim-nox zsh tmux ssh openssh-server aptitude silversearcher-ag expect mosh git-flow

## set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

##
useradd --password `mkpasswd $PASSWORD` -m -s /bin/zsh -U $USER

groupadd rbenv

adduser $USER rbenv

chown -R $USER:rbenv /usr/local/rbenv
chmod -R ug+rwx /usr/local/rbenv

## enable user local services for the configured user

mkdir -p /etc/sv/runsvdir-$USER
cat << EOF > /etc/sv/runsvdir-$USER/run
#!/bin/sh
exec 2>&1
exec chpst -u$USER runsvdir /home/$USER/Local/service
EOF

chmod +x /etc/sv/runsvdir-$USER/run

mkdir -p /etc/sv/runsvdir-$USER/log
cat << EOF > /etc/sv/runsvdir-$USER/log/run
#!/bin/sh
mkdir -p /var/log/runsvdir-$USER
exec svlogd -tt /var/log/runsvdir-$USER
EOF

chmod +x /etc/sv/runsvdir-$USER/log/run

ln -s /etc/sv/runsvdir-$USER /etc/service/

su $USER<<EOUS

export HOME=/home/$USER
cd ~

cat << EOF > .secrets

export DEVDIR=\\\$HOME/Development
EOF

git config --global user.email "$EMAIL"
git config --global user.name "$NAME"

cat << EOF > .gemrc
---
:backtrace: false
:benchmark: false
:bulk_threshold: 1000
:sources:
- http://rubygems.org/
:update_sources: true
:verbose: true
install: "--no-rdoc --no-ri"
update: "--no-rdoc --no-ri"
gem: "--no-ri --no-rdoc"
EOF

mkdir -p .ssh
cat /authorized_keys > .ssh/authorized_keys

cat /id_rsa_plain_text > .ssh/id_rsa

cat /id_rsa.pub > .ssh/id_rsa.pub

cat << EOF > .ssh/config
IdentityFile /home/$USER/.ssh/id_rsa

Host github github.com
  StrictHostKeyChecking no
  User git
  Hostname github.com
  PreferredAuthentications publickey

EOF

chmod go-rwx .ssh/id_rsa
chmod go-rwx .ssh/authorized_keys
chmod go-wx .ssh/config

## local user services

mkdir -p sv
mkdir -p service

git clone git://github.com/andsens/homeshick.git .homesick/repos/homeshick
/bin/bash<<EOF
export HOME=/home/$USER
cd ~
echo 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \\\$*' > ssh
chmod +x ssh
export GIT_TRACE=1
export GIT_SSH="./ssh"
source ~/.homesick/repos/homeshick/homeshick.sh
homeshick --batch clone git@github.com:johnae/dotfiles
homeshick --batch clone git@github.com:johnae/dotmux
homeshick --batch clone git@github.com:johnae/dotvim
homeshick link --force
echo "Setting default ruby..."
source /etc/profile.d/rbenv.sh
rbenv global mri
#sed -ri "s/NeoBundleCheck/\"NeoBundleCheck/g" ~/.vimrc 
#vim +NeoBundleUpdate! +qall 2>&1
EOF

## I think vim exits above in such a way that anything after doesn't run
#/bin/bash<<EOF
#export HOME=/home/$USER
#cd ~
#echo 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \\\$*' > ssh
#chmod +x ssh
#export GIT_TRACE=1
#export GIT_SSH="./ssh"
#source ~/.homesick/repos/homeshick/homeshick.sh
##rm -f ~/.vimrc
#echo "Relinking homeshick dotfiles..."
#homeshick link --force
#
#echo "Setting default ruby..."
#source /etc/profile.d/rbenv.sh
#rbenv global mri
#EOF


/bin/zsh<<EOF
export HOME=/home/$USER
cd ~
echo 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \\\$*' > ssh
chmod +x ssh
export GIT_TRACE=1
export GIT_SSH="./ssh"
echo "Setting up zsh..."
source ~/.zshrc
EOF

rm /home/$USER/ssh

cat /id_rsa > .ssh/id_rsa

EOUS

mkdir -p /etc/sv
mkdir -p /etc/service
mkdir -p /etc/sv/sshd/log
cat << EOF > /etc/sv/sshd/run
#!/bin/bash

mkdir -p /var/run/sshd
exec /usr/sbin/sshd -D
EOF
cat << EOF > /etc/sv/sshd/log/run
#!/bin/bash

mkdir -p /var/log/sshd
exec svlogd -tt /var/log/sshd
EOF

chmod +x /etc/sv/sshd/run
chmod +x /etc/sv/sshd/log/run

ln -s /etc/sv/sshd /etc/service/

sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

cat <<EOF> /etc/sudoers.d/100_users
$USER ALL=(ALL) NOPASSWD:ALL
Defaults:$USER env_keep += "SSH_AUTH_SOCK"
EOF

chmod 0440 /etc/sudoers.d/100_users

cd /home/$USER
echo "Will now tar the user directory..."
ls -lah
tar cf /home/$USER.tar .
cd /
rm -rf /home/$USER
mkdir -p /home/$USER
chown -R $USER:$USER /home/$USER

cat <<EOF> /setup_user
#!/bin/bash

if [ ! -e /home/$USER/.bootstrapped ]; then
if [ -e /home/$USER.tar ]; then
cd /home
tar xf /home/$USER.tar -C /home/$USER
touch /home/$USER/.bootstrapped
fi
fi
rm -f /home/$USER.tar
chown -R $USER:$USER /home/$USER
rm /setup_user
rm /etc/service/user_template
EOF

chmod +x /setup_user

mkdir -p /etc/sv/user_template
cat << EOF > /etc/sv/user_template/run
#!/bin/bash

exec /setup_user
EOF

chmod +x /etc/sv/user_template/run

ln -s /etc/sv/user_template /etc/service/

## add setup script for docker
cat <<EOF>/usr/local/bin/docker
#!/bin/bash
if [ ! -e /usr/local/bin/docker.io ]; then
  echo "Docker not installed, downloading and installing..."
  sudo wget https://get.docker.io/builds/Linux/x86_64/docker-latest -O /usr/local/bin/docker.io
  sudo chmod +x /usr/local/bin/docker.io
fi
sudo /usr/local/bin/docker.io \$*
EOF
chmod +x /usr/local/bin/docker

## clean up
apt-get clean
echo "Removing authorized_keys and private keys temporarily added at / previously..."
rm -f /authorized_keys /id_rsa.pub /id_rsa_plain_text /id_rsa

echo "***** USER is '$USER'"
echo "***** PASSWORD is '$PASSWORD'"