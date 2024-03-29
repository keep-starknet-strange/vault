import { usdcTransferFilter, decodeUSDCTransfer } from "./indexer_config.js";

export const config = {
  streamUrl: "https://mainnet.starknet.a5a.ch",
  startingBlock: 274621,
  network: "starknet",
  finality: "DATA_STATUS_ACCEPTED",
  filter: usdcTransferFilter,
  sinkType: "postgres",
  sinkOptions: {
    noTls: true,
    tableName: "transferUSDC",
  },
};

export default decodeUSDCTransfer;
