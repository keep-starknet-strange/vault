import { bigint, boolean, pgTable, text, timestamp } from 'drizzle-orm/pg-core';

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

export const registration = pgTable('registration', {
  phone_number: text('phone_number').primaryKey(),
  address: text('address'),
  first_name: text('first_name'),
  last_name: text('last_name'),
  created_at: timestamp('created_at').defaultNow(),
  is_confirmed: boolean('is_confirmed').default(false),
  _cursor: bigint('_cursor', { mode: 'number' }),
});
