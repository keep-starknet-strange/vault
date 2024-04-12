import { otp } from '@/db/schema';
import { desc } from 'drizzle-orm';
import type { FastifyInstance } from 'fastify';

interface VerifyOtpRequestBody {
  phone_number: string;
  sent_otp: string;
}

export default function verifyOtp(fastify: FastifyInstance) {
  fastify.post<{
    Body: VerifyOtpRequestBody;
  }>(
    '/verify-otp',
    {
      schema: {
        body: {
          type: 'object',
          required: ['phone_number'],
          properties: {
            phone_number: { type: 'string', pattern: '^\\+[1-9]\\d{1,14}$' },
            sent_otp: { type: 'string', pattern: '^d{6}$' },
          },
        },
      },
    },
    async (request, reply) => {
      try {
        const { phone_number, sent_otp } = request.body;

        // validating the otp
        // - if otp is old or otp is already used
        const otp_record = await fastify.db.query.otp
          .findFirst({
            where: {
              phone_number: phone_number,
              otp: sent_otp,
            },
            orderBy: [desc(otp.created_at)],
          })
          .execute();

        if (!otp_record) {
          return reply.code(200).send({ message: 'You need to request the otp first' });
        }

        // update the otp as used
        await fastify.db.query.otp.updateOne({
          where: {
            phone_number: phone_number,
            otp: sent_otp,
          },
          set: {
            used: true,
          },
        });

        // update the user record as confirmed
        await fastify.db.query.registration.updateOne({
          where: {
            phone_number: phone_number,
          },
          set: {
            is_confirmed: true,
          },
        });

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
