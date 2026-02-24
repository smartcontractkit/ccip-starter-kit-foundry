import path from 'node:path'
import { fileURLToPath } from 'node:url'
import dotenv from 'dotenv'

import { EVMChain } from '@chainlink/ccip-sdk'
import { viemWallet } from '@chainlink/ccip-sdk/viem'
import { createWalletClient, defineChain, http, parseUnits, toHex } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'

type SendMode = 'data' | 'token' | 'token-data'

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

dotenv.config({ path: path.resolve(__dirname, '..', '..', '.env') })

function printUsage(): void {
  console.log('CCIP v2 send demo (generic lane)')
  console.log('')
  console.log('Usage:')
  console.log(
    '  npm --prefix sdk-examples run ccip-send -- --mode <data|token|token-data> --router <SOURCE_ROUTER> --receiver <RECEIVER> [options]',
  )
  console.log('')
  console.log('Lane options:')
  console.log('  --source-rpc-url <url>     source RPC URL (or env CCIP_SOURCE_RPC_URL / AVALANCHE_FUJI_RPC_URL)')
  console.log('  --dest-rpc-url <url>       destination RPC URL (or env CCIP_DEST_RPC_URL / ETHEREUM_SEPOLIA_RPC_URL)')
  console.log('')
  console.log('Message options:')
  console.log('  --block-confirmations <n>  default: 1 (0 = default finality, >0 = Faster Than Finality)')
  console.log('  --token <TOKEN_ADDRESS>    required for token modes')
  console.log('  --amount <value>           token amount in human units (default: 1)')
  console.log('  --data <text>              payload text (default: hello from sdk-examples)')
  console.log('  --fee-token <native|link|address>  default: native')
  console.log('  --gas-limit <value>        default: 0 for token-only, 200000 otherwise')
  console.log('  --dry-run                  quote only, do not send')
}

function hasFlag(name: string): boolean {
  return process.argv.includes(name)
}

function getArg(name: string): string | undefined {
  const idx = process.argv.indexOf(name)
  if (idx === -1 || idx + 1 >= process.argv.length) return undefined
  const value = process.argv[idx + 1]
  if (!value || value.startsWith('--')) return undefined
  return value
}

function requireArg(name: string): string {
  const value = getArg(name)
  if (!value) throw new Error(`Missing required argument: ${name}`)
  return value
}

function getEnvFirst(names: string[]): string | undefined {
  for (const name of names) {
    const value = process.env[name]
    if (value) return value
  }
  return undefined
}

function resolveRpcUrl(flagName: '--source-rpc-url' | '--dest-rpc-url'): string {
  const fromFlag = getArg(flagName)
  if (fromFlag) return fromFlag

  const fromEnv =
    flagName === '--source-rpc-url'
      ? getEnvFirst(['CCIP_SOURCE_RPC_URL', 'AVALANCHE_FUJI_RPC_URL'])
      : getEnvFirst(['CCIP_DEST_RPC_URL', 'ETHEREUM_SEPOLIA_RPC_URL'])
  if (fromEnv) return fromEnv

  if (flagName === '--source-rpc-url') {
    throw new Error(
      'Missing source RPC URL. Pass --source-rpc-url or set CCIP_SOURCE_RPC_URL (fallback AVALANCHE_FUJI_RPC_URL).',
    )
  }
  throw new Error(
    'Missing destination RPC URL. Pass --dest-rpc-url or set CCIP_DEST_RPC_URL (fallback ETHEREUM_SEPOLIA_RPC_URL).',
  )
}

function normalizeMode(input: string): SendMode {
  if (input === 'data' || input === 'token' || input === 'token-data') return input
  throw new Error(`Unsupported mode: ${input}. Use one of: data, token, token-data`)
}

function parseBlockConfirmations(input: string): number {
  if (!/^\d+$/.test(input)) throw new Error(`Invalid --block-confirmations value: ${input}`)
  const parsed = Number(input)
  if (!Number.isSafeInteger(parsed) || parsed < 0 || parsed > 65535) {
    throw new Error('--block-confirmations must be an integer between 0 and 65535')
  }
  return parsed
}

function requireUserKey(): `0x${string}` {
  const key = process.env.USER_KEY ?? process.env.PRIVATE_KEY
  if (!key) {
    throw new Error('Missing USER_KEY (or PRIVATE_KEY) in environment')
  }
  return key.startsWith('0x') ? (key as `0x${string}`) : (`0x${key}` as `0x${string}`)
}

async function resolveFeeToken(source: EVMChain, router: string, feeTokenInput: string): Promise<string> {
  if (feeTokenInput === 'native') return ZERO_ADDRESS
  if (feeTokenInput.startsWith('0x')) return feeTokenInput
  if (feeTokenInput === 'link') {
    const feeTokens = await source.getFeeTokens(router)
    for (const [address, info] of Object.entries(feeTokens)) {
      if (info.symbol.toUpperCase() === 'LINK') return address
    }
    throw new Error('LINK fee token not found for source router')
  }
  throw new Error(`Unsupported --fee-token value: ${feeTokenInput}`)
}

async function main(): Promise<void> {
  if (hasFlag('--help')) {
    printUsage()
    return
  }

  const mode = normalizeMode(requireArg('--mode'))
  const router = requireArg('--router')
  const receiver = requireArg('--receiver')
  const sourceRpcUrl = resolveRpcUrl('--source-rpc-url')
  const destRpcUrl = resolveRpcUrl('--dest-rpc-url')

  const token = getArg('--token')
  const amountInput = getArg('--amount') ?? '1'
  const payload = getArg('--data') ?? 'hello from sdk-examples'
  const feeTokenInput = (getArg('--fee-token') ?? 'native').toLowerCase()
  const blockConfirmations = parseBlockConfirmations(getArg('--block-confirmations') ?? '1')
  const dryRun = hasFlag('--dry-run')
  const gasLimit = BigInt(getArg('--gas-limit') ?? (mode === 'token' ? '0' : '200000'))

  if ((mode === 'token' || mode === 'token-data') && !token) {
    throw new Error('--token is required for token modes')
  }

  const source = await EVMChain.fromUrl(sourceRpcUrl)
  const dest = await EVMChain.fromUrl(destRpcUrl)
  const destChainSelector = dest.network.chainSelector
  const feeToken = await resolveFeeToken(source, router, feeTokenInput)

  const tokenAmounts: Array<{ token: string; amount: bigint }> = []
  if (mode === 'token' || mode === 'token-data') {
    const tokenInfo = await source.getTokenInfo(token!)
    tokenAmounts.push({
      token: token!,
      amount: parseUnits(amountInput, tokenInfo.decimals),
    })
  }

  const message = {
    receiver,
    data: mode === 'token' ? '0x' : toHex(payload),
    tokenAmounts,
    feeToken,
    extraArgs: {
      gasLimit,
      blockConfirmations,
    },
  }

  const fee = await source.getFee({
    router,
    destChainSelector,
    message,
  })

  console.log({
    mode,
    sourceNetwork: source.network.name,
    sourceChainSelector: source.network.chainSelector.toString(),
    destNetwork: dest.network.name,
    destChainSelector: destChainSelector.toString(),
    router,
    receiver,
    blockConfirmations,
    feeToken,
    fee: fee.toString(),
  })

  if (dryRun) return

  const account = privateKeyToAccount(requireUserKey())
  const sourceViemChain = defineChain({
    id: source.network.chainId,
    name: source.network.name,
    nativeCurrency: { name: 'Native', symbol: 'NATIVE', decimals: 18 },
    rpcUrls: { default: { http: [sourceRpcUrl] } },
    testnet: source.network.networkType === 'TESTNET',
  })
  const walletClient = createWalletClient({
    account,
    chain: sourceViemChain,
    transport: http(sourceRpcUrl),
  })

  const request = await source.sendMessage({
    router,
    destChainSelector,
    message: {
      ...message,
      fee,
    },
    wallet: viemWallet(walletClient),
  })

  console.log({
    txHash: request.tx.hash,
    messageId: request.message.messageId,
  })
}

main().catch((error) => {
  console.error('CCIP v2 send demo failed')
  console.error(error)
  process.exitCode = 1
})
