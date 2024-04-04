import { Block, formatUnits, hash, uint256 } from "./deps.ts";
import { USDC_ADDRESS, USDC_DECIMALS } from "./usdc.ts";

const filter = {
  header: {
    weak: true,
  },
  events: [
    {
      fromAddress: USDC_ADDRESS,
      keys: [hash.getSelectorFromName("Transfer")],
      includeReceipt: false,
    },
  ],
};

export const config = {
  streamUrl: "https://mainnet.starknet.a5a.ch",
  startingBlock: 274621,
  network: "starknet",
  finality: "DATA_STATUS_ACCEPTED",
  filter,
  sinkType: "postgres",
  sinkOptions: {
    tableName: "transfer_usdc",
  },
};

export default function decodeUSDCTransfers({ header, events }: Block) {
  const { blockNumber, blockHash, timestamp } = header!;

  return (events ?? []).map(({ event, transaction }) => {
    const transactionHash = transaction.meta.hash;
    const transferId = `${transactionHash}_${event.index ?? 0}`;

    const [fromAddress, toAddress, amountAddedLow, amountAddedHigh] =
      event.data;

    const amountBn = uint256.uint256ToBN({
      low: amountAddedLow,
      high: amountAddedHigh,
    });
    const amount = formatUnits(amountBn, USDC_DECIMALS);

    return {
      network: "starknet-mainnet",
      block_hash: blockHash,
      block_number: +blockNumber,
      block_timestamp: timestamp,
      transaction_hash: transactionHash,
      transfer_id: transferId,
      from_address: fromAddress,
      to_address: toAddress,
      amount,
      created_at: new Date().toISOString(),
    };
  });
}
