# Chainlink CCIP Starter Kit V2 (Foundry)

> **Disclaimer:**
>
> _Please note, this repo contains community examples only  — these are not Chainlink products or services and are not supported or maintained by Chainlink. This code represents an example of using a Chainlink product or service, and is intended for demonstration and educational purposes only. It is provided “AS IS” and “AS AVAILABLE” without warranties of any kind, may not have been audited, and may omit checks or error handling. Each party intending to use this example code does so entirely at their own risk and must perform its own audits, security and code review, key management, and testing before any production deployment and ensure the operation and performance of such code matches expectations. Neither Chainlink Labs nor the Chainlink Foundation deploys, operates, monitors, maintains or endorses any deployment of this code. Note that this is not a Chainlink product, feature or service, and there are no commitments made with respect to the code, including compatibility with future Chainlink releases. You should not rely on this code without first conducting your own technical, engineering, and security review. This code is also outside the scope of any Chainlink bug bounty programs. Neither Chainlink Labs, the Chainlink Foundation, nor Chainlink node operators are responsible for outcomes due to errors in this example or how it is deployed or operated, or liable for any resulting claims or damages. Use of the Chainlink Network is subject to the Chainlink Foundation [Terms of Service](https://chain.link/terms), which provides important information and disclosures. By using this code, you acknowledge and agree to these terms._

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
- `test/`: testing suite powered by Chainlink Local V3 (no RPC needed)
- `test/fork/`: fork tests for Examples 06–08 (manual run, needs RPC URLs and pinned blocks, see below)

## Minimal Setup

```bash
cp .env.example .env
```

Set at least:

- `ETHEREUM_SEPOLIA_RPC_URL`
- `POLYGON_AMOY_RPC_URL`

Then follow the book chapters for exact run commands. 

## Fork Tests (Examples 06–08)

`forge test` runs the no-fork Chainlink Local tests only. The CCT examples (06–08) deploy tokens and pools and register
them in the live TokenAdminRegistry, so their tests run the real scripts against pinned forks of Ethereum Sepolia and
Polygon Amoy. They are run manually; there is no CI job for them.

Requirements: Foundry >= 1.5.1 and RPC URLs for both chains. The forks are pinned to blocks committed in
`test/fork/utils/CCTForkTest.sol` (`DEFAULT_SEPOLIA_FORK_BLOCK`, `DEFAULT_AMOY_FORK_BLOCK`), so a fresh clone runs the same
chain state. Pinned blocks need an archive RPC once they fall out of a provider's recent-state window.

```bash
FOUNDRY_PROFILE=fork forge test -j 1 -vv
```

To run against a different block, for example the latest one to check whether the live lane has drifted:

```bash
ETHEREUM_SEPOLIA_FORK_BLOCK=$(cast block-number --rpc-url $ETHEREUM_SEPOLIA_RPC_URL) \
POLYGON_AMOY_FORK_BLOCK=$(cast block-number --rpc-url $POLYGON_AMOY_RPC_URL) \
FOUNDRY_PROFILE=fork forge test -j 1 -vv
```
