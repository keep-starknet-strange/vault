import {
	Block,
	FieldElement,
	Filter,
	formatUnits,
	hash,
	uint256,
} from "./deps.ts";
import { balanceStorageLocation, USDC_ADDRESS, USDC_DECIMALS } from "./usdc.ts";

const filter: Filter = {
	header: {
		weak: true,
	},
	events: [
		{
			fromAddress: USDC_ADDRESS,
			keys: [hash.getSelectorFromName("Transfer") as FieldElement],
			includeReceipt: false,
		},
	],
	stateUpdate: {
		storageDiffs: [{ contractAddress: USDC_ADDRESS }],
	},
};

let streamUrl =
	(Deno.env.get("NETWORK") || "testnet") === "MAINNET"
		? "https://mainnet.starknet.a5a.ch"
		: "https://sepolia.starknet.a5a.ch";
let startingBlock = Number(Deno.env.get("STARTING_BLOCK")) || 0;

export const config = {
	streamUrl,
	startingBlock,
	network: "starknet",
	finality: "DATA_STATUS_ACCEPTED",
	filter,
	sinkType: "postgres",
	sinkOptions: {
		tableName: "balance_usdc",
	},
};

export default function decodeUSDCBalances({
	header,
	events,
	stateUpdate,
}: Block) {
	const { blockNumber, timestamp } = header!;

	// Step 1: collect addresses that have been part of a transfer.
	const addresses = (events ?? []).reduce((addresses, { event }) => {
		const [fromAddress, toAddress] = event.data;
		addresses.add(fromAddress);
		addresses.add(toAddress);
		return addresses;
	}, new Set<string>());

	// Step 2: collect balances for each address.
	const storageDiffs = stateUpdate?.stateDiff?.storageDiffs ?? [];
	if (storageDiffs.length !== 1) {
		throw new Error("Inconsistent state update.");
	}

	const storageEntries = storageDiffs[0].storageEntries;

	return Array.from(addresses).map((address) => {
		const location = balanceStorageLocation(address);
		// Notice that balances may use 2 felts.
		const entryLow = storageEntries.find(
			(entry) => BigInt(entry.key) === location,
		);
		const entryHigh = storageEntries.find(
			(entry) => BigInt(entry.key) === location + 1n,
		);

		const balanceBn = uint256.uint256ToBN({
			low: entryLow?.value ?? 0n,
			high: entryHigh?.value ?? 0n,
		});

		return {
			network: "starknet-mainnet",
			block_number: +blockNumber,
			block_timestamp: timestamp,
			address,
			balance: formatUnits(balanceBn, USDC_DECIMALS),
		};
	});
}
