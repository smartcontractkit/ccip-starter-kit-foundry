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

### RPC URLs

Set RPC URLs in a local `.env` file (do not commit secrets):

```bash
cp .env.example .env
```

Populate RPC URL variables only for the chains you actually plan to run.

In `foundry.toml`, each chain alias points to an env var (for example `avalancheFuji = "${AVALANCHE_FUJI_RPC_URL}"`).

If a variable is missing in `.env`, commands using the corresponding alias will fail.

## Chain Configuration

Always pull the latest values from the [CCIP Directory](https://docs.chain.link/ccip/directory/) before running examples.
