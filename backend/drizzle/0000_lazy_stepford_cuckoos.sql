CREATE TABLE IF NOT EXISTS "claims" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"amount" text,
	"nonce" integer,
	"address" text,
	"signature" text[],
	CONSTRAINT "claims_address_nonce_unique" UNIQUE("address","nonce")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "mock_limit" (
	"address" text PRIMARY KEY NOT NULL,
	"limit" text,
	"block_timestamp" timestamp
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "otp" (
	"phone_number" text PRIMARY KEY NOT NULL,
	"otp" text,
	"used" boolean DEFAULT false,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "registration" (
	"phone_number" text PRIMARY KEY NOT NULL,
	"nickname" text,
	"created_at" timestamp DEFAULT now(),
	"contract_address" text DEFAULT '',
	"is_confirmed" boolean DEFAULT false
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "balance_usdc" (
	"network" text,
	"block_number" bigint,
	"block_timestamp" timestamp,
	"address" text,
	"balance" text,
	"_cursor" bigint
);
--> statement-breakpoint
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
