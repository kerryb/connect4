#!/bin/bash
#
# Server setup script

set -x
set -e
user="connect4"
base_dir="/opt/connect4"
database_root="/var/lib/pgsql"
database_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
set -u
set -o pipefail
umask 022

setup() {
  relax_crypto_policy
  create_user
  set_up_release_dirs
  set_up_maintenance_page_dir
  install_nginx
  set_up_nginx
  install_postgres
  set_up_postgres  
  create_database
  set_up_environment
  install_systemd_service
  post_install_message
}

relax_crypto_policy() {
  # to allow SHA1 and stop yum etc from failing (BT default is FUTURE:AD-SUPPORT)
  update-crypto-policies --set DEFAULT:AD-SUPPORT
}

create_user() {
  if ! grep -q "^${user}:" /etc/passwd ; then
    useradd -m -s /bin/bash -d ${base_dir} "${user}"
  fi
}

set_up_release_dirs() {
  mkdir -p "${base_dir}/releases"
  mkdir -p "${base_dir}/shared/var"
  cp files/connect4/deploy-release.sh ${base_dir}
  chown -R ${user} ${base_dir}
  chmod +x ${base_dir}/deploy-release.sh
}

set_up_maintenance_page_dir() {
  local dir="/etc/${user}"
  mkdir -p $dir
  chown $user $dir
  chmod a+r $dir
}

install_nginx() {
  yum install -y yum-utils
  cp files/yum/nginx.repo /etc/yum.repos.d/nginx.repo
  yum install -y nginx
}

set_up_nginx() {
  rm -f /etc/nginx/conf.d/*
  cp files/nginx/connect4.conf /etc/nginx/conf.d/
  cp files/nginx/maintenance.html /etc/connect4/maintenance.html.disabled
  sed -i.bak '/^[# ]   server {/,/^[# ]    }/d' /etc/nginx/nginx.conf
  mkdir -p /etc/nginx/ssl
  if [[ ! -f /etc/nginx/ssl/connect4.cert ]] ; then
    cp files/nginx/connect4.cert /etc/nginx/ssl/
    cp files/nginx/connect4.key /etc/nginx/ssl/
  fi  
  setsebool -P httpd_can_network_connect 1
  systemctl enable nginx
  systemctl start nginx
}

install_postgres() {
  dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  dnf -qy module disable postgresql
  dnf install -y postgresql14-server
}

set_up_postgres() {
  if [[ ! -e ${database_root}/14/data ]] ; then
    /usr/pgsql-14/bin/postgresql-14-setup initdb
    systemctl enable postgresql-14
    systemctl stop postgresql-14
    systemctl start postgresql-14
  fi
}

create_database() {
  sudo -iu postgres <<EOSUDO

  if ! psql -tac '\dg' | grep -q 'connect4' ; then
    psql <<EOSQL
    create role connect4 with encrypted password '${database_password}' createdb login;
    create database connect4 owner connect4;
EOSQL
  fi
EOSUDO
}

set_up_environment() {
  if ! [[ -f ${base_dir}/connect4.env ]] ; then
    cat <<EOF >> ${base_dir}/connect4.env
RELEASE_NAME='connect4'
RUN_ERL_LOG_MAXSIZE=200000
RUN_ERL_LOG_GENERATIONS=50
SECRET_KEY_BASE='$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 1)'
DATABASE_URL='ecto://connect4:${database_password}@localhost/connect4'
PHX_SERVER=true
EOF
  fi

  if ! grep -q connect4\.env ${base_dir}/.bash_profile ; then
    echo 'source connect4.env' >> ${base_dir}/.bash_profile
    sed 's/^\([^=]*\)=.*/export \1/' ${base_dir}/connect4.env >> ${base_dir}/.bash_profile
  fi

  if [[ ! -f ${base_dir}/.profile ]] ; then
    ln -s ${base_dir}/.{bash_,}profile
  fi
}


install_systemd_service() {
  cp files/connect4/connect4.service /usr/lib/systemd/system/connect4.service
  systemctl enable connect4
  echo "${user} ALL=(root) NOPASSWD: /bin/systemctl * connect4" > /etc/sudoers.d/${user}
}

post_install_message() {
  cat <<EOF

Installation complete. Now perform the following manual steps:

  * replace self-signed SSL cert and key in /etc/nginx/ssl/
  * sudo systemctl restart nginx
  * install the Phoenix application as ${user} using deploy-release.sh

EOF
}

setup
