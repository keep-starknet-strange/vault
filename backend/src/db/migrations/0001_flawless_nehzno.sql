CREATE TABLE IF NOT EXISTS "balance_usdc" (
	"network" text,
	"block_number" bigint,
	"block_timestamp" timestamp,
	"address" text,
	"balance" text,
	"_cursor" bigint
);
