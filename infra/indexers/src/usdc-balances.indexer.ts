import { USDC_ADDRESS } from './constants.ts';
import sql from './db.ts';
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
const startingBlock = Number(Deno.env.get('STARTING_BLOCK')) ?? 0

export const config = {
	streamUrl,
	startingBlock,
	network: 'starknet',
	finality: 'DATA_STATUS_ACCEPTED',
	filter,
	sinkType: 'postgres',
	sinkOptions: {
		tableName: 'balance_usdc',
    entityMode: true,
	},
}

export default async function decodeUSDCBalances({
	header,
	events,
	stateUpdate,
}: Block) {
	const { blockNumber, timestamp } = header!

	// Step 1: collect addresses that have been part of a transfer.
	const allAddresses = new Set<string>()
	const recipientAddresses = new Set<string>()

	for (const { event } of events ?? []) {
		if (!event.data) continue
		const [fromAddress, toAddress] = event.data

		allAddresses.add(fromAddress)
		allAddresses.add(toAddress)

		recipientAddresses.add(toAddress)
	}

	// Setp 2: get existing balances from db to decide if a balance needs to be inserted or updated
	const balances = await sql`
	SELECT
		address
	FROM
		balance_usdc
	WHERE
		address
	IN
		(${Array.from(recipientAddresses).join(',')})
	`
	const balancesSet = balances.reduce<Set<string>>((acc, { address }) => {
		acc.add(address)
		return acc
	}, new Set())

	// Step 3: collect balances for each address.
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

	return Array.from(allAddresses).map((address) => {
		const addressBalanceLocation = getStorageLocation(address, 'balances')

		const addressBalanceLow = storageMap.get(addressBalanceLocation)
		const addressBalanceHigh = storageMap.get(addressBalanceLocation + 1n)

		const balanceBn = uint256.uint256ToBN({
			low: addressBalanceLow ?? 0n,
			high: addressBalanceHigh ?? 0n,
		})

		return balancesSet.has(address) ? {
				entity: {
					address
				},
				update: {
					block_number: +(blockNumber ?? 0),
					block_timestamp: timestamp,
					balance: balanceBn.toString(),
				}
			}: {
				insert: {
					network: 'starknet-sepolia',
					block_number: +(blockNumber ?? 0),
					block_timestamp: timestamp,
					address,
					balance: balanceBn.toString(),
				}
			}
	})
}
