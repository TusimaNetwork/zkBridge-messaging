# zkBridge Messaging

![Tusima zkBridge](https://ucarecdn.com/f4e08f06-c238-47f8-b98a-97629c199377/bridgelogo.png)

**Messaging** is the primary module of Tusima zkBridge, providing a set of `Solidity` language APIs. Through these APIs, developers can seamlessly transmit messages from the source chain to the destination chain, thus enabling the creation of omnichain applications.

From the perspective of message verification, the Messaging module currently comprises two cross-chain mechanisms. **One relies on the On-chain Light Client to achieve cross-chain communication, while the other uses its existing message verification mechanism to enable cross-chain communication between the Ethereum mainnet (currently Goerli) and zkRollup solutions like zkSync, Polygon zkEVM, and more.** 

More detailed information please refer to [here](https://tusima.gitbook.io/zkbridge/how-does-it-work/messaging).

## Build with source code

We are using **Foundry**, so before you build this project, make sure you have installed Foundry.

> Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust. More detailed information please refer to their [doc](https://book.getfoundry.sh/).

Below are some commonly used Foundry commands:

```shell
# Build
$ forge build
# Test
$ forge test
# Format
$ forge fmt
```

### Deploy
1. Create a `.env` file, and edit it and fill in the corresponding fields.
    ```shell
    $ cp .env.example .env
    $ vim .env
    $ source .env
    ```
2. Execute deploy cmd.
    ```shell
    $ forge script script/DeployMessaging.s.sol:DeployMessing --broadcast --verify --rpc-url <Network_RPC_URL>
    ```