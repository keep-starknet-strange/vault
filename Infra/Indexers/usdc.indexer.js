import { hash, uint256 } from "https://esm.run/starknet@5.14";
import { formatUnits } from "https://esm.run/viem@1.4";

const USDC_ADDRESS =
  "0x53c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8";

const USDC_DECIMALS = 6;

const usdcTransferFilter = {
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

function decodeUSDCTransfer({ header, events }) {
  const { blockNumber, blockHash, timestamp } = header;
  return (events ?? []).map(({ event, transaction }) => {
    const transactionHash = transaction.meta.hash;
    const transferId = `${transactionHash}_${event.index ?? 0}`;

    const [from_address, to_address, amount_addedLow, amount_addedHigh] =
      event.data;

    const amount_bn = uint256.uint256ToBN({
      low: amount_addedLow,
      high: amount_addedHigh,
    });
    const amount = formatUnits(amount_bn, USDC_DECIMALS);

    return {
      network: "starknet-mainnet",
      block_hash: blockHash,
      block_number: +blockNumber,
      block_timestamp: timestamp,
      transaction_hash: transactionHash,
      transfer_id: transferId,
      from_address: from_address,
      to_address: to_address,
      amount: amount,
      created_at: new Date().toISOString(),
    };
  });
}

export const config = {
  streamUrl: "https://mainnet.starknet.a5a.ch",
  startingBlock: 274621,
  network: "starknet",
  finality: "DATA_STATUS_ACCEPTED",
  filter: usdcTransferFilter,
  sinkType: "postgres",
  sinkOptions: {
    noTls: true,
    tableName: "transfer_usdc",
  },
};

export default decodeUSDCTransfer;
