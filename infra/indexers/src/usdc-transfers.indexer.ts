import { SN_CHAIN_ID, STREAM_URLS, USDC_ADDRESSES, STARTING_BLOCK, BALANCES_VAR_NAMES } from './constants.ts';
import { Block, hash, uint256 } from './deps.ts'
import { getStorageLocation } from './utils.ts';

const filter = {
	header: {
		weak: true,
	},
	events: [
		{
			fromAddress: USDC_ADDRESSES[SN_CHAIN_ID],
			keys: [hash.getSelectorFromName('Transfer')],
			includeReceipt: false,
		},
	],
	stateUpdate: {
		storageDiffs: [{ contractAddress: USDC_ADDRESSES[SN_CHAIN_ID] }],
	},
}

const streamUrl = STREAM_URLS[SN_CHAIN_ID]
const startingBlock = STARTING_BLOCK

export const config = {
	streamUrl,
	startingBlock,
	network: 'starknet',
	finality: 'DATA_STATUS_PENDING',
	filter,
	sinkType: 'postgres',
	sinkOptions: {
		tableName: 'transfer_usdc',
	},
}

function getBalance(storageMap: Map<bigint, bigint>, address: string): bigint {
	const addressBalanceLocation = getStorageLocation(address, BALANCES_VAR_NAMES[SN_CHAIN_ID])

	const addressBalanceLow = storageMap.get(addressBalanceLocation)
	const addressBalanceHigh = storageMap.get(addressBalanceLocation + 1n)

	return uint256.uint256ToBN({
		low: addressBalanceLow ?? 0n,
		high: addressBalanceHigh ?? 0n,
	})
}

export default function decodeUSDCTransfers({ header, events, stateUpdate }: Block) {
	const { blockNumber, blockHash, timestamp } = header!

	// Step 2: collect balances for each address.
	const storageMap = new Map<bigint, bigint>()
	const storageDiffs = stateUpdate?.stateDiff?.storageDiffs ?? []

	console.log(storageDiffs)

	for (const storageDiff of storageDiffs) {
		for (const storageEntry of storageDiff.storageEntries ?? []) {
			if (!storageEntry.key || !storageEntry.value) {
				continue
			}

			const key = BigInt(storageEntry.key)
			const value = BigInt(storageEntry.value)

			storageMap.set(key, value)
		}
	}

	// Setp 3: aggregate everyting
	return (events ?? [])
		.map(({ event, transaction }) => {
			if (!event.data) return null

			const transactionHash = transaction.meta.hash
			const transferId = `${transactionHash}_${event.index ?? 0}`
			const IndexInBlock = (transaction.meta.transactionIndex ?? 0) * 1_000 + (event.index ?? 0)

			const [fromAddress, toAddress, amountAddedLow, amountAddedHigh] =
				event.data

			const amountBn = uint256.uint256ToBN({
				low: amountAddedLow,
				high: amountAddedHigh,
			})

			const senderBalance = getBalance(storageMap, fromAddress)
			const recipientBalance = getBalance(storageMap, toAddress)

			return {
				network: 'starknet-sepolia',
				block_hash: blockHash,
				block_number: +(blockNumber ?? 0),
				block_timestamp: timestamp,
				transaction_hash: transactionHash,
				transfer_id: transferId,
				from_address: fromAddress,
				to_address: toAddress,
				amount: amountBn.toString(),
				index_in_block: IndexInBlock,
				sender_balance: senderBalance.toString(),
				recipient_balance: recipientBalance.toString(),
				created_at: new Date().toISOString(),
			}
		})
		.filter(Boolean)
}
