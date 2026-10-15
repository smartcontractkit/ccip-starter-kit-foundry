# AGENTS.md

Guidance for AI coding agents and contributors working in this repo.

## What this repo is

Chainlink CCIP Starter Kit V2 (Foundry): community example code for learning CCIP 2.0 — Foundry scripts, small
sender/receiver contracts, SDK demos, and an mdBook tutorial. It is **example code, not audited, not for production**.
Keep the disclaimer headers on example contracts and scripts.

## Layout

- `script/examples/`: CCIP 2.0 example scripts (`Example01`–`Example08`) and `Legacy01`–`Legacy02`. Core learning path.
- `script/EncodeExtraArgsOffchain.s.sol`: ExtraArgs V1/V2/V3 encoding helper used by the examples.
- `src/`: `BasicMessageSender`, `BasicMessageReceiver`, `BasicMessageReceiverWithCCVs`, `utils/Withdraw`.
- `test/`: Foundry tests on the Chainlink Local V3 no-fork simulator (see below). `test/fork/`: fork tests for
  Examples 06–08, excluded from plain `forge test`.
- `book/src/`: mdBook chapters, one per example. Build output (`book/book`) is gitignored.
- `sdk-examples/`: TypeScript CCIP SDK demos (Node >= 24), separate from the Foundry project.
- `lib/`: git submodules. Versions are pinned in `foundry.lock`; import paths are in `remappings.txt`.

## Cloning and submodules

Clone **without** `--recursive` and initialize submodules one level deep:

```bash
git clone https://github.com/smartcontractkit/ccip-starter-kit-foundry
cd ccip-starter-kit-foundry
git submodule update --init
```

Do not use `git clone --recursive` or `git submodule update --init --recursive`. `lib/chainlink-local` has its own
nested submodules (`chainlink-ccip`, `chainlink-ace`, `forge-std`, ...) that duplicate large libraries already in
`lib/`. They are unused here: `remappings.txt` points every import at the top-level libs. `forge install` with no
arguments also initializes submodules recursively (seen when adding `chainlink-local`), so prefer the git command
above for a fresh checkout.

## Commands

```bash
forge build
forge test                  # no-fork Chainlink Local tests, no RPC needed
forge fmt --check test      # tests are formatted; keep them that way
mdbook serve book --open    # preview the book
```

Scripts need RPC URLs: `cp .env.example .env` and set the endpoints (at minimum `ETHEREUM_SEPOLIA_RPC_URL` and
`POLYGON_AMOY_RPC_URL`). Never commit `.env`. Run commands for each example are in its book chapter.

## Toolchain and dependency pins

- `solc 0.8.26`, `evm_version = cancun` (set in `foundry.toml`; CCIP 2.0 contracts need Cancun opcodes).
- `@chainlink/contracts-ccip` = `contracts-ccip-v2.0.0`, `@chainlink/contracts` = `contracts-v1.5.0`,
  `@chainlink/local` = `v0.3.1` (Chainlink Local V3). Local v0.3.x pins the first two, so bump them together.
- When adding or bumping a submodule, confirm `foundry.lock` has a matching entry. An interrupted `forge install`
  can add the submodule without writing the lock entry.

## Tests (Chainlink Local V3)

- Base contract: `test/utils/LocalSimulatorTest.sol` deploys `CCIPLocalSimulator` and exposes the router, LINK, BnM.
- `Example01–05.t.sol` call the real script `run()` functions rather than copies of their logic, so script
  regressions fail tests. Scripts use `vm.startBroadcast()` with no argument, so in tests the sender is
  `DEFAULT_SENDER` (exposed as `broadcaster`): fund it with tokens/ETH before calling a script.
- The local router charges only what `router.setFee(...)` sets, defaults to 0, and uses a mock message ID.
- Local mode is single-chain with no token pools, no CCV verifiers (so no quorum check), and no executor or manual
  execution. It does enforce the CCIP 2.0 finality rules, one token per message, and receiver CCV config validation.
  Do not assert behavior Local does not model; note the limitation in the test instead.
- Examples 06–08 (CCT token/pool setup) are covered by fork tests in `test/fork/` (Sepolia -> Amoy). They run the real
  scripts against pinned forks through `CCIPLocalSimulatorFork`, need Foundry >= 1.5.1, and are excluded from plain
  `forge test`. Run them manually with `FOUNDRY_PROFILE=fork forge test -j 1`; there is no CI job. Contracts or scripts
  created in a fork test are per-fork: make them persistent (`_persistent` in `test/fork/utils/CCTForkTest.sol`)
  before using them on another fork.
- Fork pins: `DEFAULT_SEPOLIA_FORK_BLOCK` and `DEFAULT_AMOY_FORK_BLOCK` in `test/fork/utils/CCTForkTest.sol` are
  committed so runs are reproducible; `ETHEREUM_SEPOLIA_FORK_BLOCK` / `POLYGON_AMOY_FORK_BLOCK` override them for a run.
  Pinned state never sees testnet upgrades, so green tests only prove the examples against that snapshot.
- Re-pinning: do it when the book's lane/CCV/finality behavior changes, when a pinned block can no longer be served
  (non-archive RPC), and on every `@chainlink/contracts-ccip` or `@chainlink/local` bump. Steps: run the fork profile
  with the two override env vars set to the latest blocks (`cast block-number --rpc-url ...`); if all tests pass, put those
  block numbers into the two constants and commit them; if not, the live lane drifted: fix the tests or the examples
  and the book first.
- Prefer specific `vm.expectRevert(<selector or message>)` over bare `vm.expectRevert()`.

## Working rules

- Keep changes scoped. Example scripts and contracts mirror the book chapters: if you change one, update the other.
- Do not remove or soften the example/audit disclaimers.
- Generated or local-only files stay untracked: `.env`, `out/`, `cache/`, `broadcast/` logs, `testing/*.tsv`,
  `book/book`, `node_modules/`.
