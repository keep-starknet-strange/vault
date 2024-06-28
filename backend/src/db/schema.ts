import { bigint, boolean, integer, pgTable, text, timestamp, unique, uuid } from 'drizzle-orm/pg-core'

export const usdcTransfer = pgTable('transfer_usdc', {
  transferId: text('transfer_id').primaryKey(),
  network: text('network'),
  blockHash: text('block_hash'),
  blockNumber: bigint('block_number', { mode: 'number' }),
  blockTimestamp: timestamp('block_timestamp', { withTimezone: false }),
  indexedAt: timestamp('indexed_at', { withTimezone: false }),
  transactionHash: text('transaction_hash'),
  fromAddress: text('from_address'),
  toAddress: text('to_address'),
  amount: text('amount'),
  indexInBlock: bigint('index_in_block', { mode: 'number' }),
  senderBalance: text('sender_balance'),
  recipientBalance: text('recipient_balance'),
  createdAt: timestamp('created_at', { withTimezone: false }),
  cursor: bigint('_cursor', { mode: 'number' }),
})

export const registration = pgTable('registration', {
  phone_number: text('phone_number').primaryKey(),
  nickname: text('nickname'),
  created_at: timestamp('created_at').defaultNow(),
  contract_address: text('contract_address').default(''),
  is_confirmed: boolean('is_confirmed').default(false),
})

export const claims = pgTable(
  'claims',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    amount: text('amount'),
    nonce: integer('nonce'),
    address: text('address'),
    signature: text('signature').array(),
  },
  (t) => ({
    unq: unique().on(t.address, t.nonce),
  }),
)

export const mockLimit = pgTable('mock_limit', {
  address: text('address').primaryKey(),
  limit: text('limit'),
  blockTimestamp: timestamp('block_timestamp', { withTimezone: false }),
})
