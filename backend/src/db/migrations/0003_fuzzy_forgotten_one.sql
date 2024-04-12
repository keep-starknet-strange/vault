ALTER TABLE "registration" ADD PRIMARY KEY ("phone_number");--> statement-breakpoint
ALTER TABLE "registration" ALTER COLUMN "phone_number" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "registration" ADD COLUMN "is_confirmed" boolean;