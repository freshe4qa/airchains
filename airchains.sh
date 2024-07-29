#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export AIRCHAINS_CHAIN_ID=junction" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages
apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# install go
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source .bash_profile

# download binary
cd $HOME && mkdir -p go/bin/
wget https://github.com/airchains-network/junction/releases/download/v0.1.0/junctiond
chmod +x junctiond
mv junctiond $HOME/go/bin/

# config
junctiond config set client chain-id junction
junctiond config set client keyring-backend test

# init
junctiond init $NODENAME --chain-id $AIRCHAINS_CHAIN_ID

# download genesis and addrbook
curl -L https://snapshots-testnet.nodejumper.io/airchains-testnet/genesis.json > $HOME/.junction/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/airchains-testnet/addrbook.json > $HOME/.junction/config/addrbook.json

# set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.00025amf\"|" $HOME/.junction/config/app.toml

# set peers and seeds
SEEDS="575e98598e9813a26576759c7ef70fd38d2516a4@junction-testnet-rpc.synergynodes.com:15656,04e2fdd6ec8f23729f24245171eaceae5219aa91@airchains-testnet-seed.itrocket.net:19656,aeaf101d54d47f6c99b4755983b64e8504f6132d@airchain-testnet-peer.dashnode.org:28656,bb26fc8cef05cee75d4cae3f25e17d74c7913967@airchains-t.seed.stavr.tech:4476,df949a46ae6529ae1e09b034b49716468d5cc7e9@testnet-seeds.stakerhouse.com:13756,48887cbb310bb854d7f9da8d5687cbfca02b9968@35.200.245.190:26656,60133849b4c83531eb2d835970035a0f08868658@65.109.93.124:28156,df2a56a208821492bd3d04dd2e91672657c79325@airchain-testnet-peer.cryptonode.id:27656,04e2fdd6ec8f23729f24245171eaceae5219aa91@airchains-testnet-seed.itrocket.net:19656,3dc2f101876e1a26730f99c06a5a2eb6e2cc2349@65.21.69.53:33656"
PEERS="38ffaf594a80b88ffaa0ecb3847bf0f77e5c52fe@5.9.87.231:36656,27d1c8383350eb11dc3cbba4b222d4e892e0ec03@45.250.254.41:19656,8b2a63f074a37bbfebd82cb78a4893936e1dfd61@37.27.132.57:19656,5880ddf4518b061c111ae6bf07b1ef76ef2a42af@158.220.100.154:26656,36ed02b04e84fb0ba6382d8d1cd2dbe3195a235b@37.27.64.237:10156,d1c949abeb7805546eca0b5e60c4889649760b9c@65.108.121.227:13356,2d7a9e2e7ac0dc46c688f85bff05bba43f0aa576@[2a0a:4cc0:0:52:18c3:bfff:fe4b:eaae]:29956,264493e01774cccdb9baabee4af7146acbec67f2@65.21.193.80:63656,4f84487af5e8a86baa7e4e428ca7156ae5bc3ab7@148.251.235.130:24656,9ba635344d9c64a4b1d82d7e1138d0216afc27c4@167.235.14.83:34656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.junction/config/config.toml

# disable indexing
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.junction/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.junction/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.junction/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.junction/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.junction/config/app.toml
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.junction/config/app.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.junction/config/config.toml

# create service
sudo tee /etc/systemd/system/junctiond.service > /dev/null << EOF
[Unit]
Description=Airchains Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which junctiond) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# reset
junctiond tendermint unsafe-reset-all --home $HOME/.junction --keep-addr-book 
curl https://snapshots-testnet.nodejumper.io/airchains-testnet/airchains-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.junction

# start service
sudo systemctl daemon-reload
sudo systemctl enable junctiond
sudo systemctl restart junctiond

break
;;

"Create Wallet")
junctiond keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
AIRCHAINS_WALLET_ADDRESS=$(junctiond keys show $WALLET -a)
AIRCHAINS_VALOPER_ADDRESS=$(junctiond keys show $WALLET --bech val -a)
echo 'export AIRCHAINS_WALLET_ADDRESS='${AIRCHAINS_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export AIRCHAINS_VALOPER_ADDRESS='${AIRCHAINS_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Create Validator")
junctiond tx staking create-validator \
--amount=1000000amf \
--pubkey=$(junctiond tendermint show-validator) \
--moniker=$NODENAME \
--chain-id=junction \
--commission-rate=0.10 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation=1 \
--from=wallet \
--gas-prices=0.00025amf \
--gas-adjustment=1.5 \
--gas=300000 \
-y
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
