ALTER TABLE "claims" ALTER COLUMN "nonce" SET DATA TYPE integer;--> statement-breakpoint
ALTER TABLE "claims" ALTER COLUMN "nonce" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "claims" ADD COLUMN "address" text;--> statement-breakpoint
ALTER TABLE "claims" ADD CONSTRAINT "claims_address_nonce_unique" UNIQUE("address","nonce");