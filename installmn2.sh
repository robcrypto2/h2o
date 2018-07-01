echo "Installing required packages";

#Swap part
dd if=/dev/zero of=/mnt/myswap.swap bs=1M count=4000
mkswap /mnt/myswap.swap
chmod 0600 /mnt/myswap.swap
swapon /mnt/myswap.swap

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install git -y
sudo apt-get install curl -y
sudo apt-get install nano -y
sudo apt-get install wget -y
sudo apt-get install -y pwgen
sudo apt-get install build-essential libtool automake autoconf -y
sudo apt-get install autotools-dev autoconf pkg-config libssl-dev -y
sudo apt-get install libgmp3-dev libevent-dev bsdmainutils libboost-all-dev -y
sudo apt-get install libzmq3-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y

echo "Done installing";
YOURIP=`wget -qO- eth0.me`
PSS=`pwgen -1 20 -n`

cd $HOME
echo "Getting H2O client";
sudo mkdir $HOME/h2o
git clone https://github.com/h2oproject/h2o.git h2o
cd $HOME/h2o
chmod 777 autogen.sh
./autogen.sh
./configure --disable-tests --disable-gui-tests
chmod 777 share/genbuild.sh
sudo make
sudo make install

echo "In order to proceed with the installation, please paste Masternode genkey by clicking right mouse button. Once masternode genkey is visible in the terminal please hit ENTER.";
read MNKEY


sudo mkdir $HOME/.h2ocore

#printf "rpcuser=user\nrpcpassword=$PSS\nrpcallowip=127.0.0.1\nmaxconnections=500\ndaemon=1\nserver=1\nlisten=1\nrpcport=13356\nexternalip=$YOURIP:13355\nmasternodeprivkey=$MNKEY\nmasternode=1" > /$HOME/.h2ocore/h2o.conf

#Updated by robcrypto2 to add nodes 7/1/2018
printf "rpcuser=user\nrpcpassword=$PSS\nrpcallowip=127.0.0.1\nmaxconnections=500\ndaemon=1\nserver=1\nlisten=1\nrpcport=13356\nexternalip=$YOURIP:13355\nmasternodeprivkey=$MNKEY\nmasternode=1\naddnode=31.14.139.7:13355\naddnode=82.223.49.215:13355\naddnode=45.32.218.231:13355\naddnode=45.76.2.91:13355\naddnode=104.207.145:13355" > /$HOME/.h2ocore/h2o.conf


echo "Starting H2O client";
h2od --daemon
sleep 5
echo "Syncing...";
until h2o-cli mnsync status | grep -m 1 '"IsSynced": true'; do sleep 1 ; done > /dev/null 2>&1
echo "Sync complete. You can start Master Node.";
