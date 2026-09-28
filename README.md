# Chainlink CCIP Starter Kit V2 (Foundry)

> **Note**
>
> _This repository represents an example of using a Chainlink product or service. It is provided to help you understand how to interact with Chainlink’s systems so that you can integrate them into your own. This template is provided "AS IS" without warranties of any kind, has not been audited, and may be missing key checks or error handling to make the usage of the product more clear. Take everything in this repository as an example and not something to be copy pasted into a production ready service._

Reference starter kit for learning and testing **CCIP v2** with Foundry scripts, Solidity contracts, and small SDK examples.

Examples 01–08 use Ethereum Sepolia → Polygon Amoy as their primary CCIP 2.0 lane.
[Example 01](book/src/examples/example01-token-transfer-faster-than-finality.md), Example 03, and
Example 04 use faucet-issued CCIP-BnM.
[Examples 06–08](book/src/examples/example06-cct01-burnmint-token-and-pool-setup.md) teach custom
token and pool deployment. The legacy chapters retain their older-lane demonstrations.

## Start Here

The primary documentation for this repo lives in the book: 
- https://smartcontractkit.github.io/ccip-starter-kit-foundry/

You can also run the book locally:

```bash
mdbook serve book --open
```

## Repo Scope

- `script/examples`: Foundry CCIP v2 examples (core learning path)
- `src`: sender/receiver contracts used by examples
- `book/src`: step-by-step tutorial chapters
- `sdk-examples`: minimal CCIP SDK demos

## Minimal Setup

```bash
cp .env.example .env
```

Set at least:

- `ETHEREUM_SEPOLIA_RPC_URL`
- `POLYGON_AMOY_RPC_URL`

Then follow the book chapters for exact run commands.
