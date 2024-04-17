import { otp, registration } from '@/db/schema';
import { and, desc, sql } from 'drizzle-orm';
import { eq } from 'drizzle-orm/pg-core/expressions';
import type { FastifyInstance } from 'fastify';

interface VerifyOtpRequestBody {
  phone_number: string;
  sent_otp: string;
}

export function verifyOtp(fastify: FastifyInstance) {
  fastify.post<{
    Body: VerifyOtpRequestBody;
  }>(
    '/verify_otp',
    {
      schema: {
        body: {
          type: 'object',
          required: ['phone_number'],
          properties: {
            phone_number: { type: 'string', pattern: '^\\+[1-9]\\d{1,14}$' },
            sent_otp: { type: 'string' },
          },
        },
      },
    },
    async (request, reply) => {
      try {
        const { phone_number, sent_otp } = request.body;

        // validating the otp
        // - if otp is old or otp is already used
        const otp_record = await fastify.db
          .select()
          .from(otp)
          .where(
            and(eq(otp.phone_number, phone_number), eq(otp.otp, sent_otp), eq(otp.used, false)),
          )
          .orderBy(desc(otp.created_at))
          .limit(1);

        if (otp_record.length === 0) {
          return reply
            .code(400)
            .send({ message: 'You need to request the otp first | Invalid OTP provided' });
        }

        // update the otp as used
        await fastify.db
          .update(otp)
          .set({
            used: true,
          })
          .where(eq(otp.phone_number, phone_number));

        // update the user record as confirmed
        await fastify.db
          .update(registration)
          .set({
            is_confirmed: true,
          })
          .where(eq(registration.phone_number, phone_number));

        return reply.code(200).send({
          message: 'OTP verified successfully',
        });
      } catch (error) {
        fastify.log.error(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
      }
    },
  );
}
