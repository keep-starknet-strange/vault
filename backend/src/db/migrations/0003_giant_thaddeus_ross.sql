CREATE TABLE IF NOT EXISTS "otp" (
	"phone_number" text,
	"otp" text,
	"used" boolean DEFAULT false,
	"created_at" timestamp DEFAULT now()
);
