import { EVMChain, getMessagesForSender } from '@chainlink/ccip-sdk'
import { inspect } from 'node:util'
import { getArg, hasFlag, resolveRpcUrl } from './helpers.js'

function printUsage(): void {
  console.log('CCIP v2 tracking demo (source chain)')
  console.log('')
  console.log('Usage:')
  console.log('  npm --prefix sdk-examples run ccip-track -- --tx-hash <SOURCE_TX_HASH> [--source-rpc-url <url>]')
  console.log('  npm --prefix sdk-examples run ccip-track -- --message-id <MESSAGE_ID> [--source-rpc-url <url>]')
  console.log(
    '  npm --prefix sdk-examples run ccip-track -- --sender <SENDER_ADDRESS> [--limit 10] [--start-block 0] [--source-rpc-url <url>]',
  )
}

function parseNonNegativeInt(name: string, input: string, fallback: number): number {
  const raw = input.trim()
  if (!raw) return fallback
  if (!/^\d+$/.test(raw)) throw new Error(`${name} must be a non-negative integer`)
  const parsed = Number(raw)
  if (!Number.isSafeInteger(parsed)) throw new Error(`${name} must be a safe integer`)
  return parsed
}

function pruneUndefined(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(pruneUndefined)
  }
  if (!value || typeof value !== 'object') {
    return value
  }
  const out: Record<string, unknown> = {}
  for (const [k, v] of Object.entries(value)) {
    if (v === undefined) continue
    const pruned = pruneUndefined(v)
    if (pruned !== undefined) out[k] = pruned
  }
  return out
}

function asNonNegativeInt(value: unknown): number | undefined {
  if (typeof value === 'number' && Number.isFinite(value) && value >= 0) return Math.trunc(value)
  if (typeof value === 'bigint' && value >= 0n) return Number(value)
  if (typeof value === 'string' && /^\d+$/.test(value)) return Number(value)
  return undefined
}

function summaryOfRequest(request: any): Record<string, unknown> {
  const finalityThreshold =
    request?.message?.blockConfirmations ??
    request?.message?.extraArgs?.blockConfirmations ??
    request?.message?.finality
  const finalityThresholdInt = asNonNegativeInt(finalityThreshold)

  const transactionSpeed =
    finalityThresholdInt === undefined
      ? undefined
      : finalityThresholdInt === 0
        ? 'default finality'
        : 'faster than finality'

  const tokenAmounts = Array.isArray(request?.message?.tokenAmounts)
    ? request.message.tokenAmounts
        .map((tokenAmount: any) =>
          pruneUndefined({
            token: tokenAmount?.token ?? tokenAmount?.sourceTokenAddress,
            amount: tokenAmount?.amount,
          }),
        )
        .filter((tokenAmount: any) => tokenAmount.token || tokenAmount.amount)
    : undefined

  const ccipFees = pruneUndefined({
    feeToken: request?.message?.feeToken,
    amount: request?.message?.feeTokenAmount,
  }) as Record<string, unknown>

  const verifiers =
    (Array.isArray(request?.message?.ccvs) && request.message.ccvs.length > 0 ? request.message.ccvs : undefined) ??
    (Array.isArray(request?.message?.verifiers) && request.message.verifiers.length > 0
      ? request.message.verifiers
      : undefined)

  return pruneUndefined({
    messageId: request?.message?.messageId,
    sourceTxHash: request?.tx?.hash ?? request?.log?.transactionHash ?? request?.message?.sendTransactionHash,
    destTxHash: request?.metadata?.receiptTransactionHash ?? request?.message?.receiptTransactionHash,
    status: request?.metadata?.status ?? request?.message?.status,
    sourceChain:
      request?.metadata?.sourceNetworkInfo?.name ??
      request?.metadata?.sourceNetworkInfo?.chainSelector ??
      request?.lane?.sourceChainSelector,
    destChain:
      request?.metadata?.destNetworkInfo?.name ??
      request?.metadata?.destNetworkInfo?.chainSelector ??
      request?.lane?.destChainSelector,
    txTimestamp: request?.tx?.timestamp ?? request?.message?.sendTimestamp,
    origin: request?.message?.origin ?? request?.message?.sender,
    from: request?.tx?.from ?? request?.message?.sender,
    to: request?.tx?.to ?? request?.log?.address ?? request?.message?.receiver,
    ccipFees: Object.keys(ccipFees).length > 0 ? ccipFees : undefined,
    tokensAndAmountsSent: tokenAmounts && tokenAmounts.length > 0 ? tokenAmounts : undefined,
    data: request?.message?.data,
    senderNonce: request?.message?.nonce,
    gasLimit: request?.message?.gasLimit ?? request?.message?.extraArgs?.gasLimit,
    sequenceNumber: request?.message?.sequenceNumber,
    transactionSpeed,
    finalityThreshold: finalityThresholdInt ?? finalityThreshold,
    verifiers,
    executor: request?.message?.executor,
  }) as Record<string, unknown>
}

function printSummary(prefix: string, request: unknown): void {
  const useColors = !process.env.NO_COLOR
  const title = useColors ? `\x1b[36m${prefix}\x1b[0m` : prefix
  console.log(title)
  console.log(
    inspect(summaryOfRequest(request), {
      colors: useColors,
      depth: null,
      compact: false,
      sorted: false,
    }),
  )
}

async function main(): Promise<void> {
  if (hasFlag('--help')) {
    printUsage()
    return
  }

  const txHash = getArg('--tx-hash')
  const messageId = getArg('--message-id')
  const sender = getArg('--sender')
  const sourceRpcUrl = resolveRpcUrl('--source-rpc-url')

  const selectedModes = [Boolean(txHash), Boolean(messageId), Boolean(sender)].filter(Boolean).length
  if (selectedModes === 0) {
    printUsage()
    process.exitCode = 1
    return
  }
  if (selectedModes > 1) {
    throw new Error('Provide exactly one of --tx-hash, --message-id, or --sender')
  }

  const chain = await EVMChain.fromUrl(sourceRpcUrl)

  if (txHash) {
    const requests = await chain.getMessagesInTx(txHash)
    console.log(`found ${requests.length} message(s) in tx ${txHash}`)
    for (let i = 0; i < requests.length; i++) {
      printSummary(`request ${i + 1}:`, requests[i])
    }
    return
  }

  if (messageId) {
    const request = await chain.getMessageById(messageId)
    printSummary('request:', request)
    return
  }

  const limit = parseNonNegativeInt('--limit', getArg('--limit') ?? '10', 10)
  const startBlock = parseNonNegativeInt('--start-block', getArg('--start-block') ?? '0', 0)

  let count = 0
  for await (const request of getMessagesForSender(chain, sender!, { startBlock })) {
    printSummary(`request ${count + 1}:`, request)
    count++
    if (count >= limit) break
  }
}

main().catch((error) => {
  console.error('CCIP v2 tracking demo failed')
  console.error(error)
  process.exitCode = 1
})
