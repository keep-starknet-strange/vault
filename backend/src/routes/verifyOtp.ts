import { otp, registration } from '@/db/schema';
import { and, desc } from 'drizzle-orm';
import { eq } from 'drizzle-orm/pg-core/expressions';
import type { FastifyInstance } from 'fastify';
import { type Account, uint256 } from 'starknet';

interface VerifyOtpRequestBody {
  phone_number: string;
  sent_otp: string;
  public_key_x: string;
  public_key_y: string;
}

export function verifyOtp(fastify: FastifyInstance, account: Account, classHash: string) {
  fastify.post<{
    Body: VerifyOtpRequestBody;
  }>(
    '/verify_otp',
    {
      schema: {
        body: {
          type: 'object',
          required: ['phone_number', 'public_key_x', 'public_key_y', 'sent_otp'],
          properties: {
            phone_number: { type: 'string', pattern: '^\\+[1-9]\\d{1,14}$' },
            sent_otp: { type: 'string', pattern: '^[0-9]{6}$' },
            public_key_x: { type: 'string', pattern: '^0x[0-9a-fA-F]{64}$' },
            public_key_y: { type: 'string', pattern: '^0x[0-9a-fA-F]{64}$' },
          },
        },
      },
    },
    async (request, reply) => {
      try {
        const { phone_number, sent_otp, public_key_x, public_key_y } = request.body;

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

        if (!otp_record.length) {
          return reply.code(400).send({
            message: 'You need to request the otp first | Invalid OTP provided',
          });
        }

        // update the otp as used
        await fastify.db
          .update(otp)
          .set({
            used: true,
          })
          .where(eq(otp.phone_number, phone_number));

        // public key, approver, limit
        const { contract_address, transaction_hash } = await account.deployContract({
          classHash,
          constructorCalldata: [
            uint256.bnToUint256(public_key_x),
            uint256.bnToUint256(public_key_y),
            0,
            1000000000,
            0,
          ],
        });
        fastify.log.info(
          'Deploying account: ',
          contract_address,
          ' for: ',
          phone_number,
          ' with tx hash: ',
          transaction_hash,
        );

        if (!contract_address) {
          return reply.code(500).send({
            message: 'Error in deploying smart contract. Please try again later',
          });
        }

        // update the user record as confirmed and add the account address
        await fastify.db
          .update(registration)
          .set({
            is_confirmed: true,
            contract_address,
          })
          .where(eq(registration.phone_number, phone_number));

        return reply.code(200).send({
          message: 'OTP verified successfully',
        });
      } catch (error) {
        fastify.log.error(error);
        console.log(error);
        return reply.code(500).send({ message: 'Internal Server Error' });
      }
    },
  );
}
