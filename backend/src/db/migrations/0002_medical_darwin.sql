CREATE TABLE IF NOT EXISTS "registration" (
	"phone_number" text PRIMARY KEY NOT NULL,
	"address" text,
	"first_name" text,
	"last_name" text,
	"created_at" timestamp DEFAULT now(),
	"is_confirmed" boolean DEFAULT false
);
