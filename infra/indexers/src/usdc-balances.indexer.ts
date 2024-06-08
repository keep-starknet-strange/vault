import { USDC_ADDRESS } from './constants.ts';
import {
	Block,
	FieldElement,
	Filter,
	hash,
	uint256,
} from './deps.ts'
import { getStorageLocation } from './utils.ts'

const filter: Filter = {
	header: {
		weak: true,
	},
	events: [
		{
			fromAddress: USDC_ADDRESS,
			keys: [hash.getSelectorFromName('Transfer') as FieldElement],
			includeReceipt: false,
		},
	],
	stateUpdate: {
		storageDiffs: [{ contractAddress: USDC_ADDRESS }],
	},
}

// TODO: multiple chains support
const streamUrl = 'https://sepolia.starknet.a5a.ch'
const startingBlock = Number(Deno.env.get('STARTING_BLOCK')) || 0

export const config = {
	streamUrl,
	startingBlock,
	network: 'starknet',
	finality: 'DATA_STATUS_ACCEPTED',
	filter,
	sinkType: 'postgres',
	entityMode: true,
	sinkOptions: {
		tableName: 'balance_usdc',
	},
}

export default function decodeUSDCBalances({
	header,
	events,
	stateUpdate,
}: Block) {
	const { blockNumber, timestamp } = header!

	// Step 1: collect addresses that have been part of a transfer.
	const addresses = (events ?? []).reduce<Set<string>>((acc, { event }) => {
		if (!event.data) return acc

		const [fromAddress, toAddress] = event.data

		acc.add(fromAddress)
		acc.add(toAddress)

		return acc
	}, new Set())

	// Step 2: collect balances for each address.
	const storageMap = new Map<bigint, bigint>()
	const storageDiffs = stateUpdate?.stateDiff?.storageDiffs ?? []

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

	return Array.from(addresses).map((address) => {
		const addressBalanceLocation = getStorageLocation(address, 'balances')

		const addressBalanceLow = storageMap.get(addressBalanceLocation)
		const addressBalanceHigh = storageMap.get(addressBalanceLocation + 1n)

		const balanceBn = uint256.uint256ToBN({
			low: addressBalanceLow ?? 0n,
			high: addressBalanceHigh ?? 0n,
		})

		return {
			network: 'starknet-sepolia',
			block_number: +(blockNumber ?? 0),
			block_timestamp: timestamp,
			address,
			balance: balanceBn.toString(),
		}
	})
}
