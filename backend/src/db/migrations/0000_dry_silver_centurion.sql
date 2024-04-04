CREATE TABLE IF NOT EXISTS "transfer_usdc" (
	"transfer_id" text PRIMARY KEY NOT NULL,
	"network" text,
	"block_hash" text,
	"block_number" bigint,
	"block_timestamp" timestamp,
	"transaction_hash" text,
	"from_address" text,
	"to_address" text,
	"amount" text,
	"created_at" timestamp,
	"_cursor" bigint
);
