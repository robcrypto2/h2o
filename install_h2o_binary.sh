#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='h2o.conf'
CONFIGFOLDER='/root/.h2ocore'
COIN_DAEMON='h2od'
COIN_CLI='h2o-cli'
COIN_PATH='/usr/local/bin/'
COIN_NAME='H2O'
COIN_PORT=13355
RPC_PORT=13355

NODEIP=$(curl -s4 icanhazip.com)

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m" 
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'

purgeOldInstallation() {
    echo -e "${GREEN}Searching and removing old $COIN_NAME files and configurations${NC}"
    #kill wallet daemon
	sudo systemctl stop $COIN_NAME.service
    sudo killall $COIN_DAEMON > /dev/null 2>&1
    #remove old ufw port allow
    sudo ufw delete allow $COIN_PORT/tcp > /dev/null 2>&1
    #remove old files
    if [ -d "$CONFIGFOLDER" ]; then
        sudo rm -rf $CONFIGFOLDER > /dev/null 2>&1
    fi
    #remove binaries and Dextro utilities
    cd /usr/local/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && cd
    echo -e "${GREEN}* Done${NONE}";
}


function download_node() {
  echo -e "${GREEN}Downloading and Installing VPS $COIN_NAME Daemon${NC}"
  #cd $TMP_FOLDER >/dev/null 2>&1
  #rm $COIN_ZIP >/dev/null 2>&1
  cd /root/ >/dev/null 2>&1
  wget https://github.com/robcrypto2/h2o/raw/master/binaries/linux_h2o.zip
  compile_error
  unzip linux_h2o.zip >/dev/null 2>&1
  cd linux_h2o
  chmod +x $COIN_DAEMON && chmod +x $COIN_CLI
  compile_error
  cp $COIN_DAEMON $COIN_CLI $COIN_PATH
  cd - >/dev/null 2>&1
  rm -R linux_h2o* >/dev/null 2>&1
  clear
}

function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target

[Service]
User=root
Group=root

Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid

ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop

Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}


function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
staking=1
port=$COIN_PORT
EOF
}

function create_key() {
  echo -e "${YELLOW}Enter your ${RED}$COIN_NAME Masternode GEN Key${NC}. Press ENTER to auto generate"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
  $COIN_PATH$COIN_DAEMON -daemon
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
   echo -e "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the GEN Key${NC}"
    sleep 30
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
  fi
  $COIN_PATH$COIN_CLI stop
fi
clear
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=256
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY

#ADDNODES
addnode=45.76.2.91:13355
addnode=104.207.145.111:13355
addnode=45.33.1.153:13355
addnode=198.58.117.101:13355
addnode=173.230.152.232:13355
addnode=45.77.230.171:13355
addnode=217.69.2.130:13355
addnode=31.14.139.7:13355
addnode=82.223.49.215:13355
addnode=45.32.218.231:13355
addnode=47.92.86.21
addnode=80.211.54.226
addnode=149.28.51.180
addnode=173.212.225.221
addnode=104.238.186.55
addnode=123.30.240.108
addnode=138.68.68.253
addnode=149.28.136.160
addnode=176.126.246.50
addnode=45.76.230.226
addnode=80.98.42.201
addnode=149.28.78.157
addnode=207.148.106.88
addnode=62.138.18.152
addnode=80.211.45.102
addnode=80.240.28.135
addnode=89.69.82.255
addnode=104.254.247.188
addnode=144.202.17.7
addnode=207.148.112.205
addnode=45.63.99.154
addnode=45.77.90.12
addnode=103.8.78.140
addnode=207.246.110.109
addnode=45.77.149.26
addnode=80.240.27.159
addnode=80.240.31.106
addnode=149.28.167.37
addnode=163.172.179.243
addnode=202.182.102.104
addnode=137.74.92.217
addnode=14.241.167.98
addnode=80.211.59.47
addnode=104.236.77.15
addnode=144.202.58.94
addnode=144.202.114.123
addnode=173.249.2.15
addnode=206.189.237.142
addnode=217.69.4.166
addnode=18.188.67.143
addnode=80.211.45.112
addnode=83.243.67.227
addnode=140.82.44.54
addnode=149.28.52.185
addnode=94.177.216.189
addnode=173.230.152.232
addnode=209.250.224.202
addnode=80.211.227.8
addnode=35.205.58.201
addnode=47.92.24.122
addnode=80.211.58.209
addnode=202.182.120.81
addnode=207.148.4.175
addnode=88.90.218.38
addnode=104.238.146.218
addnode=107.191.52.198
addnode=149.28.62.50
addnode=167.99.12.253
addnode=14.241.167.96
addnode=47.92.78.47
addnode=80.211.0.102
addnode=88.90.219.158
addnode=139.99.161.212
addnode=144.217.231.216
addnode=35.233.195.20
addnode=35.237.47.130
addnode=95.179.137.133
addnode=95.216.137.159
addnode=47.92.73.47
addnode=69.64.39.177
addnode=80.211.153.58
addnode=80.240.20.99
addnode=94.177.199.184
addnode=107.191.101.3
addnode=145.239.92.155
addnode=45.77.236.82
addnode=80.211.58.224
addnode=104.207.131.71
addnode=139.99.36.45
addnode=149.28.36.171
addnode=207.148.123.214
addnode=94.177.202.68
addnode=95.216.141.159
addnode=199.195.116.17
addnode=207.148.80.190
addnode=195.133.147.179
addnode=94.177.198.237
addnode=144.202.20.195
addnode=149.28.125.71
addnode=140.82.5.97
addnode=140.82.25.238
addnode=173.35.221.165
addnode=173.249.51.26
addnode=176.223.129.172
addnode=185.65.246.187
addnode=202.182.98.50
addnode=31.14.139.7
addnode=208.167.248.51
addnode=45.77.109.228


EOF
}


function enable_firewall() {
  echo -e "Please Wait until setup is finished..."
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}


function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}


function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
  echo -e "${RED}$COIN_NAME is already installed.${NC}"
  exit 1
fi
}

function prepare_system() {
echo -e "Preparing the VPS to setup. ${CYAN}$COIN_NAME${NC} ${RED}Masternode${NC}"
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
apt-get install unzip nano -y >/dev/null 2>&1
echo -e "${PURPLE}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install libzmq3-dev -y >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev  libdb5.3++ unzip libzmq5 >/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pkg-config libevent-dev libdb5.3++ unzip libzmq5"
 exit 1
fi
clear
}

function important_information() {
 echo -e "${BLUE}================================================================================================================================${NC}"
 echo -e "$COIN_NAME Masternode is up and running listening on port ${GREEN}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "VPS_IP:PORT ${GREEN}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE GENKEY is: ${RED}$COINKEY${NC}"
 echo -e "Please check ${RED}$COIN_NAME${NC} is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "Use ${RED}$COIN_CLI getinfo${NC} to check your syncing blocks."
 echo -e "Use ${RED}$COIN_CLI mnsync status${NC} to check Sync Completed TRUE."
 echo -e "Use ${RED}$COIN_CLI masternode status${NC} to check your MN."
 echo -e "${BLUE}================================================================================================================================"

}

function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  configure_systemd
  important_information
}


##### Main #####
clear

purgeOldInstallation
checks
prepare_system
download_node
setup_node

