import { otp, registration } from '@/db/schema';
import { sendMessage } from '@/utils/sms';
import { desc, eq } from 'drizzle-orm';
import type { FastifyInstance } from 'fastify';
import otpGenerator from 'otp-generator';
import * as schema from '../db/schema';

interface GetOtpRequestBody {
  phone_number: string;
}

// OTP validity duration : 15 mins
const OTP_VALIDITY_TIME = 900;

// as + symbol is not taken into query params
// - + will be added after the number is processed
export default function getOtp(fastify: FastifyInstance) {
  fastify.get<{ Querystring: GetOtpRequestBody }>(
    '/get_otp',
    {
      schema: {
        querystring: {
          type: 'object',
          required: ['phone_number'],
          properties: {
            phone_number: { type: 'string' },
          },
        },
      },
    },
    async (request, reply) => {
      try {
        const { phone_number } = request.query as { phone_number: string };

        const processed_phone_number = `+${phone_number.trimStart()}`;

        // validating if phone number exists in db
        const record_phone_number = await fastify.db.query.registration
          .findFirst({
            where: eq(registration.phone_number, processed_phone_number),
          })
          .execute();

        if (!record_phone_number) {
          return reply
            .code(500)
            .send({ message: 'No record exists with current phone number' });
        }

        const record = await fastify.db.query.otp
          .findFirst({
            where: eq(otp.phone_number, processed_phone_number),
            orderBy: [desc(otp.created_at)],
          })
          .execute();

        // console.log(await fastify.db.query.otp.findMany());

        if (record) {
          const time_added = Date.parse(record.created_at) / 1000;
          const current_time = Math.floor(Date.now() / 1000);

          // Checking if otp already requested
          // - if time_diff <= 15 mins or otp is used: deny new otp
          // - else send new otp
          if (current_time - time_added <= OTP_VALIDITY_TIME) {
            return reply
              .code(500)
              .send({ message: 'You have already requested the OTP' });
          }

          if (record.used === true) {
            return reply.code(500).send({
              message: 'You have provided the otp which is already used',
            });
          }
        }

        const otp_gen = generateOtp();

        const send_msg_res = await sendMessage(otp_gen, processed_phone_number);
        if (send_msg_res === false) {
          fastify.log.error(
            `Error sending message to phone number : ${processed_phone_number}`,
          );
          return reply.code(500).send({
            message: 'We are facing some issues. Please try again later',
          });
        }
        await fastify.db.insert(schema.otp).values({
          phone_number: processed_phone_number,
          otp: otp_gen,
        });

        return reply.code(200).send(true);
      } catch (error) {
        fastify.log.error(error);
        console.log(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
      }
    },
  );
}

const generateOtp = (): string => {
  const otp = otpGenerator.generate(6, {
    upperCaseAlphabets: false,
    specialChars: false,
  });

  return otp;
};
