import { eq } from 'drizzle-orm/pg-core/expressions'
import type { FastifyInstance } from 'fastify'

import { registration } from '@/db/schema'

import { addressRegex } from '.'

export function getUserRoute(fastify: FastifyInstance) {
  fastify.get(
    '/get_user',

    async (request, reply) => {
      const { address } = request.query as { address?: string }

      if (!address) {
        return reply.status(400).send({ message: 'Address is required' })
      }

      // Validate address format
      if (!addressRegex.test(address)) {
        return reply.status(400).send({ message: 'Invalid address format' })
      }

      try {
        const user = await fastify.db
          .select({ user: registration.nickname })
          .from(registration)
          .where(eq(registration.contract_address, address))
          .limit(1)
          .execute()

        if (!user.length) {
          return reply.status(404).send({ message: 'User not found.' })
        }

        return reply.send(user[0])
      } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: 'Internal server error' })
      }
    },
  )
}
