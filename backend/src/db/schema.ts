import { bigint, pgTable, text, timestamp } from 'drizzle-orm/pg-core';

export const usdcTransfer = pgTable('transfer_usdc', {
  transferId: text('transfer_id').primaryKey(),
  network: text('network'),
  blockHash: text('block_hash'),
  blockNumber: bigint('block_number', { mode: 'number' }),
  blockTimestamp: timestamp('block_timestamp', { withTimezone: false }),
  transactionHash: text('transaction_hash'),
  fromAddress: text('from_address'),
  toAddress: text('to_address'),
  amount: text('amount'),
  createdAt: timestamp('created_at', { withTimezone: false }),
  cursor: bigint('_cursor', { mode: 'number' }),
});

export const usdcBalance = pgTable('balance_usdc', {
  network: text('network'),
  blockNumber: bigint('block_number', { mode: 'number' }),
  blockTimestamp: timestamp('block_timestamp', { withTimezone: false }),
  address: text('address'),
  balance: text('balance'),
  cursor: bigint('_cursor', { mode: 'number' }),
});
