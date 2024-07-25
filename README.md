<p align="center">
  <img height="100" height="auto" src="https://github.com/user-attachments/assets/8c54987a-1466-41a9-a773-232a0270d84f">
</p>

# Airchains Testnet — junction

Official documentation:
>- [Validator setup instructions](https://docs.airchains.io)

Explorer:
>- [https://testnet.junction.explorers.guru](https://testnet.junction.explorers.guru)

### Minimum Hardware Requirements
 - 4x CPUs; the faster clock speed the better
 - 8GB RAM
 - 100GB of storage (SSD or NVME)

### Recommended Hardware Requirements 
 - 8x CPUs; the faster clock speed the better
 - 64GB RAM
 - 1TB of storage (SSD or NVME)

## Set up your nibiru fullnode
```
wget https://raw.githubusercontent.com/freshe4qa/airchains/main/airchains.sh && chmod +x airchains.sh && ./airchains.sh
```

## Post installation

When installation is finished please load variables into system
```
source $HOME/.bash_profile
```

Synchronization status:
```
junctiond status 2>&1 | jq .SyncInfo
```

### Create wallet
To create new wallet you can use command below. Don’t forget to save the mnemonic
```
junctiond keys add $WALLET
```

Recover your wallet using seed phrase
```
junctiond keys add $WALLET --recover
```

To get current list of wallets
```
junctiond keys list
```

## Usefull commands
### Service management
Check logs
```
journalctl -fu junctiond -o cat
```

Start service
```
sudo systemctl start junctiond
```

Stop service
```
sudo systemctl stop junctiond
```

Restart service
```
sudo systemctl restart junctiond
```

### Node info
Synchronization info
```
junctiond status 2>&1 | jq .SyncInfo
```

Validator info
```
junctiond status 2>&1 | jq .ValidatorInfo
```

Node info
```
junctiond status 2>&1 | jq .NodeInfo
```

Show node id
```
junctiond tendermint show-node-id
```

### Wallet operations
List of wallets
```
junctiond keys list
```

Recover wallet
```
junctiond keys add $WALLET --recover
```

Delete wallet
```
junctiond keys delete $WALLET
```

Get wallet balance
```
junctiond query bank balances $AIRCHAINS_WALLET_ADDRESS
```

Transfer funds
```
junctiond tx bank send $AIRCHAINS_WALLET_ADDRESS <TO_AIRCHAINS_WALLET_ADDRESS> 10000000amf
```

### Voting
```
junctiond tx gov vote 1 yes --from $WALLET --chain-id=$AIRCHAINS_CHAIN_ID
```

### Staking, Delegation and Rewards
Delegate stake
```
junctiond tx staking delegate $AIRCHAINS_VALOPER_ADDRESS 10000000amf --from=$WALLET --chain-id=$AIRCHAINS_CHAIN_ID --gas=auto
```

Redelegate stake from validator to another validator
```
junctiond tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 10000000amf --from=$WALLET --chain-id=$AIRCHAINS_CHAIN_ID --gas=auto
```

Withdraw all rewards
```
junctiond tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$AIRCHAINS_CHAIN_ID --gas=auto
```

Withdraw rewards with commision
```
junctiond tx distribution withdraw-rewards $AIRCHAINS_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$AIRCHAINS_CHAIN_ID
```

Unjail validator
```
junctiond tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$AIRCHAINS_CHAIN_ID \
  --gas=auto
```
