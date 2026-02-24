# CCIP Examples Workspace

This directory contains TypeScript examples built with `@chainlink/ccip-sdk`.

## Install

From repo root:

```bash
npm --prefix sdk-examples install
```

Add private key:

```bash
USER_KEY=0x...
```

```bash
source .env
```

Run available scripts:

```bash
npm --prefix sdk-examples run ccip-send -- --help
npm --prefix sdk-examples run ccip-track -- --help
```

## API vs CLI vs SDK

- `CCIP API`: HTTP endpoints for querying message/transfer state and metadata
- `CCIP CLI`: terminal commands for inspect/send/manual-exec workflows
- `CCIP SDK`: TypeScript library for building CCIP features directly in your app/scripts

## Official Documentation

- Tools overview: https://docs.chain.link/ccip/tools/
- CCIP API docs: https://docs.chain.link/ccip/tools/api
- CCIP CLI docs: https://docs.chain.link/ccip/tools/cli
- CCIP SDK docs: https://docs.chain.link/ccip/tools/sdk
