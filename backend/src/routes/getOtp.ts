import { desc, eq } from 'drizzle-orm'
import type { FastifyInstance } from 'fastify'
import { VerificationListInstance } from 'twilio/lib/rest/verify/v2/service/verification'

import { registration } from '@/db/schema'

import * as schema from '../db/schema'

interface GetOtpRequestBody {
  phone_number: string
  nickname: string
}

export function getOtp(fastify: FastifyInstance, twilio_verification: VerificationListInstance) {
  fastify.post<{ Body: GetOtpRequestBody }>(
    '/get_otp',

    {
      schema: {
        body: {
          type: 'object',
          required: ['phone_number', 'nickname'],
          properties: {
            phone_number: { type: 'string', pattern: '^\\+[1-9]\\d{1,14}$' },
            nickname: { type: 'string', pattern: '^[A-Za-z]{1,20}$' },
          },
        },
      },
    },

    async (request, reply) => {
      try {
        const { phone_number, nickname } = request.body

        // validating if phone number exists in db
        const record_by_phone_number = await fastify.db
          .select()
          .from(registration)
          .where(eq(registration.phone_number, phone_number))
          .orderBy(desc(registration.created_at))

        if (!record_by_phone_number.length) {
          try {
            await fastify.db.insert(schema.registration).values({
              phone_number,
              nickname,
            })
          } catch (error: any) {
            fastify.log.error(error)
            if (error.code === '23505') {
              return reply.code(409).send({
                message: 'A user with the given phone number already exists.',
              })
            }
            return reply.code(500).send({ message: 'Internal server error' })
          }
        }

        const send_msg_res = await twilio_verification.create({
          to: phone_number,
          channel: 'sms',
        })
        if (send_msg_res.status != 'pending') {
          fastify.log.error('Error sending message to phone number')
          return reply.code(500).send({
            message: 'We are facing some issues. Please try again later',
          })
        }

        return reply.code(200).send({ ok: true })
      } catch (error) {
        fastify.log.error(error)
        return reply.code(500).send({ message: 'Internal Server Error' })
      }
    },
  )
}
