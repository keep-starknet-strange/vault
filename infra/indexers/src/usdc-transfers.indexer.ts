import { USDC_ADDRESS } from './constants.ts';
import { Block, hash, uint256 } from './deps.ts'

const filter = {
	header: {
		weak: true,
	},
	events: [
		{
			fromAddress: USDC_ADDRESS,
			keys: [hash.getSelectorFromName('Transfer')],
			includeReceipt: false,
		},
	],
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
	sinkOptions: {
		tableName: 'transfer_usdc',
	},
}

export default function decodeUSDCTransfers({ header, events }: Block) {
	const { blockNumber, blockHash, timestamp } = header!

	return (events ?? [])
		.map(({ event, transaction }) => {
			if (!event.data) return null

			const transactionHash = transaction.meta.hash
			const transferId = `${transactionHash}_${event.index ?? 0}`

			const [fromAddress, toAddress, amountAddedLow, amountAddedHigh] =
				event.data

			const amountBn = uint256.uint256ToBN({
				low: amountAddedLow,
				high: amountAddedHigh,
			})

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
				created_at: new Date().toISOString(),
			}
		})
		.filter(Boolean)
}
