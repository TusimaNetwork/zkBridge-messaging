# zkBridge-messaging

Messaging contracts of Tusima zkBridge which can help developers to send messages from a chain to another.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy

```shell
$ source .env
```
deploy Messing contract and verify:
```shell
$ forge script script/DeployMessaging.s.sol:DeployMessing --broadcast --verify --rpc-url ${ <Network_RPC_URL> }
```

verify messaging on bsc-testnet:
```shell
$ forge verify-contract --verifier-url https://api-testnet.bscscan.com/api <contrasct_address> src/Messaging.sol:Messaging --etherscan-api-key ${BSCSCAN_API_KEY} --chain bsc-testnet
```
