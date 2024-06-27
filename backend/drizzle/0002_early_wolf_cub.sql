ALTER TABLE "transfer_usdc" ADD COLUMN "indexed_at" timestamp;--> statement-breakpoint
ALTER TABLE "transfer_usdc" ADD COLUMN "index_in_block" bigint;