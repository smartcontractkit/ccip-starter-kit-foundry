import path from 'node:path'
import { fileURLToPath } from 'node:url'
import dotenv from 'dotenv'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

dotenv.config({ path: path.resolve(__dirname, '..', '..', '.env') })

export function hasFlag(name: string): boolean {
  return process.argv.includes(name)
}

export function getArg(name: string): string | undefined {
  const idx = process.argv.indexOf(name)
  if (idx === -1 || idx + 1 >= process.argv.length) return undefined
  const value = process.argv[idx + 1]
  if (!value || value.startsWith('--')) return undefined
  return value
}

export function requireArg(name: string): string {
  const value = getArg(name)
  if (!value) throw new Error(`Missing required argument: ${name}`)
  return value
}

export function getEnvFirst(names: string[]): string | undefined {
  for (const name of names) {
    const value = process.env[name]
    if (value) return value
  }
  return undefined
}

export function resolveRpcUrl(flagName: '--source-rpc-url' | '--dest-rpc-url'): string {
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

export function parseBlockConfirmations(input: string): number {
  if (!/^\d+$/.test(input)) throw new Error(`Invalid --block-confirmations value: ${input}`)
  const parsed = Number(input)
  if (!Number.isSafeInteger(parsed) || parsed < 0 || parsed > 65535) {
    throw new Error('--block-confirmations must be an integer between 0 and 65535')
  }
  return parsed
}

export function requireUserKey(): `0x${string}` {
  const key = process.env.USER_KEY ?? process.env.PRIVATE_KEY
  if (!key) {
    throw new Error('Missing USER_KEY (or PRIVATE_KEY) in environment')
  }
  return key.startsWith('0x') ? (key as `0x${string}`) : (`0x${key}` as `0x${string}`)
}
