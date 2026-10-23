# Overview

This book showcases practical usage of CCIP v2.0 in this Foundry starter kit.

The goal is not to re-teach CCIP fundamentals. It is to provide runnable example flows you can execute and adapt.

## Before You Run Any Example

> **Important: Keystore first**
>
> Use a local keystore account for script execution:
>
> ```bash
> cast wallet import myAccount --interactive
> Enter private key:
> Enter password:
> `myAccount` keystore was saved successfully. Address: <YOUR_EOA_ADDRESS_SHOULD_APPEAR_HERE>
> ```
>
> Examples in this book assume `--account myAccount`.

### Environment Variables

Commands in this book use shell variables (`$SEPOLIA_ROUTER`, `$AMOY_CHAIN_SELECTOR`, ...) instead of `<PLACEHOLDERS>` you edit inside every command. You still supply each value yourself, but only once: you set a variable, and every command that uses it picks it up.

> **How the commands handle values**
>
> - A word starting with `$` is a shell variable. Before the command runs, your shell replaces `$SEPOLIA_ROUTER` with whatever you exported under that name, so `forge` and `cast` receive the real address.
> - Nothing in this repo ships with values. You provide them in three places: your `.env` file (network constants and RPC URLs), the **Chapter Parameters** block at the top of a chapter (amounts, gas limit, receiver), and `export` lines after a deploy step (addresses you just created).
> - If a variable was never set, the shell expands it to an empty string and the command fails with a confusing argument error. Run `echo $VAR_NAME` to check a value.
> - Variables exported in a terminal last only for that terminal. In a new terminal, load `.env` again and re-export any deployed addresses.

Create your local `.env` (do not commit it):

```bash
cp .env.example .env
```

Then fill in `.env`:

1. The RPC URLs for the chains you plan to run (at minimum `ETHEREUM_SEPOLIA_RPC_URL` and `POLYGON_AMOY_RPC_URL`).
2. `MY_EOA`, your keystore address: `cast wallet address --account myAccount`.
3. The network constants for those chains (`SEPOLIA_ROUTER`, `SEPOLIA_CHAIN_SELECTOR`, `SEPOLIA_LINK`, `SEPOLIA_CCIP_BNM`, and the `AMOY_` / `FUJI_` equivalents; the CCT chapters also use `*_ARM_PROXY`, `*_REGISTRY_MODULE_OWNER_CUSTOM` and `*_TOKEN_ADMIN_REGISTRY`). Copy them from the [CCIP Directory](https://docs.chain.link/ccip/directory/).

Load the file into your shell. Do this in every new terminal, and again after you edit `.env`:

```bash
set -a; source .env; set +a
```

`set -a` exports every variable, so `forge`, `cast`, `npm` and `ccip-cli` all see them.

Each chapter then follows the same pattern:

- **Chapter parameters**: a short block of `export` lines with sensible defaults (`AMOUNT`, `GAS_LIMIT`, `BLOCK_CONFIRMATIONS`, `RECEIVER`, `FEE_TOKEN`, ...). Change a value only if you want something different.
- **Deployed addresses**: when a step deploys a contract, copy the address from the `[RESULT]` log into the `export` line shown right after the command. Later steps use it automatically.

Shared variables used across chapters:

| Variable | Meaning |
|---|---|
| `MY_EOA` | Your keystore account address |
| `RECEIVER` | Destination address for token-only transfers (defaults to `$MY_EOA`) |
| `AMOUNT` | Token amount in token decimals (`1000000000000000000` is 1 token with 18 decimals) |
| `GAS_LIMIT` | Destination callback gas (`0` for token-only transfers to an EOA) |
| `BLOCK_CONFIRMATIONS` | Fast Transfers depth (`0` is default finality) |
| `FEE_TOKEN` | Fee token address: native (`0x0000000000000000000000000000000000000000`) by default, or `$SEPOLIA_LINK` to pay in LINK |

### RPC URLs

In `foundry.toml`, each chain alias points to an env var (for example `polygonAmoy = "${POLYGON_AMOY_RPC_URL}"`).

If a variable is missing in `.env`, commands using the corresponding alias will fail.

## Chain Configuration

Always pull the latest values from the [CCIP Directory](https://docs.chain.link/ccip/directory/) before running examples.

Examples 01–10 use Sepolia → Amoy. Examples 01, 03, and 04 use faucet-issued CCIP-BnM;
Examples 06–10 deploy custom tokens. Verify the lane's `OnRamp 2.0.0` before sending.
