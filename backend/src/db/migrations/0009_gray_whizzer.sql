ALTER TABLE "registration" RENAME COLUMN "first_name" TO "nickname";--> statement-breakpoint
ALTER TABLE "otp" ADD PRIMARY KEY ("phone_number");--> statement-breakpoint
ALTER TABLE "otp" ALTER COLUMN "phone_number" SET NOT NULL;