CREATE TABLE IF NOT EXISTS "claims" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"amount" text,
	"nonce" serial NOT NULL,
	"signature" text[]
);
