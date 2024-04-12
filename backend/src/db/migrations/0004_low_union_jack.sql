CREATE TABLE IF NOT EXISTS "otp" (
	"phone_number" text,
	"otp" text,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "registration" ALTER COLUMN "created_at" SET DEFAULT now();--> statement-breakpoint
ALTER TABLE "registration" ALTER COLUMN "is_confirmed" SET DEFAULT false;