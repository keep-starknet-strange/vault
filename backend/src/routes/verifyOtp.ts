import { eq } from 'drizzle-orm/pg-core/expressions'
import type { FastifyInstance } from 'fastify'
import { type Account, addAddressPadding, uint256 } from 'starknet'
import { VerificationCheckListInstance } from 'twilio/lib/rest/verify/v2/service/verificationCheck'

import { Entrypoint, SN_CHAIN_ID, VAULT_FACTORY_ADDRESSES } from '@/constants/contracts'
import { registration } from '@/db/schema'
import { computeAddress } from '@/utils/address'
import { hashPhoneNumber } from '@/utils/phoneNumber'

interface VerifyOtpRequestBody {
  phone_number: string
  sent_otp: string
  public_key_x: string
  public_key_y: string
}

export function verifyOtp(
  fastify: FastifyInstance,
  deployer: Account,
  twilio_verification: VerificationCheckListInstance,
) {
  fastify.post<{
    Body: VerifyOtpRequestBody
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
            public_key_x: { type: 'string', pattern: '^0x[0-9a-fA-F]{54,64}$' },
            public_key_y: { type: 'string', pattern: '^0x[0-9a-fA-F]{54,64}$' },
          },
        },
      },
    },

    async (request, reply) => {
      try {
        const { phone_number, sent_otp, public_key_x, public_key_y } = request.body

        // Create a verification request to twilio
        const response = await twilio_verification
          .create({
            to: phone_number,
            code: sent_otp,
          })
          .catch((error) => {
            fastify.log.error(error)
            return { status: 'unrequested' }
          })

        // The status of the verification. Can be: `pending`, `approved`, `canceled`, `max_attempts_reached`, `deleted`, `failed` or `expired`.
        if (response.status != 'approved') {
          return reply.code(400).send({
            message: `Otp is ${response.status}.`,
          })
        }

        // check if user is already registered
        const user = (
          await fastify.db.select().from(registration).where(eq(registration.phone_number, phone_number))
        )[0]

        // user is already registered
        if (user.is_confirmed) {
          return reply.code(200).send({
            contract_address: user.contract_address,
          })
        }

        // public key, approver, limit
        const { transaction_hash } = await deployer.execute({
          contractAddress: VAULT_FACTORY_ADDRESSES[SN_CHAIN_ID],
          calldata: [
            hashPhoneNumber(phone_number),
            uint256.bnToUint256(public_key_x),
            uint256.bnToUint256(public_key_y),
          ],
          entrypoint: Entrypoint.DEPLOY_ACCOUNT,
        })

        const contractAddress = addAddressPadding(computeAddress(phone_number))

        fastify.log.info(
          'Deploying account: ',
          contractAddress,
          ' for: ',
          phone_number,
          ' with tx hash: ',
          transaction_hash,
        )

        if (!transaction_hash) {
          return reply.code(500).send({
            message: 'Error in deploying smart contract. Please try again later',
          })
        }

        // update the user record as confirmed and add the account address
        await fastify.db
          .update(registration)
          .set({
            is_confirmed: true,
            contract_address: contractAddress,
          })
          .where(eq(registration.phone_number, phone_number))

        return reply.code(200).send({
          contract_address: contractAddress,
        })
      } catch (error) {
        console.log(error)
        fastify.log.error(error)
        return reply.code(500).send({ message: 'Internal Server Error' })
      }
    },
  )
}
