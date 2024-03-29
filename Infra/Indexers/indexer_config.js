const USDC_ADDRESS =
  "0x53c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8";

// hash.getSelectorFromName("Transfer")
const TRANSFER_EVENT_KEY =
  "0x99cd8bde557814842a3121e8ddfd433a539b8c9f14bf31ebf108d12e6196e9";

export const usdcTransferFilter = {
  header: {
    weak: true,
  },
  events: [
    {
      fromAddress: USDC_ADDRESS,
      keys: [TRANSFER_EVENT_KEY],
      includeReceipt: false,
    },
  ],
};

export function decodeUSDCTransfer({ header, events }) {
  const { blockNumber, blockHash } = header;
  return events.map(({ event, transaction }) => {
    const transactionHash = transaction.meta.hash;
    const transferId = `${transactionHash}_${event.index}`;

    const [from_address, to_address, amount_addedLow, amount_addedHigh] =
      event.data;

    const amount = uint256ToBN({
      low: amount_addedLow,
      high: amount_addedHigh,
    }).toString();

    return {
      network: "starknet-mainnet",
      block_hash: blockHash,
      block_number: +blockNumber,
      transaction_hash: transactionHash,
      transfer_id: transferId,
      from_address: from_address,
      to_address: to_address,
      amount: amount,
    };
  });
}

// ? ====================================================
// ? HELPERS
// ? ====================================================

export function toBigInt(value) {
  return BigInt(value);
}

export function uint256ToBN(uint256) {
  return (toBigInt(uint256.high) << 128n) + toBigInt(uint256.low);
}
