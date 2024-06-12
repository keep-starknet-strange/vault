import { eq, max } from 'drizzle-orm'
import type { FastifyInstance } from 'fastify'

import { usdcBalance } from '@/db/schema'

import { addressRegex } from '.'

export function getBalanceRoute(fastify: FastifyInstance) {
  fastify.get(
    '/get_balance',

    async (request, reply) => {
      const { address } = request.query as { address?: string }

      if (!address) {
        return reply.status(400).send({ message: 'Address is required.' })
      }

      // Validate address format
      if (!addressRegex.test(address)) {
        return reply.status(400).send({ message: 'Invalid address format.' })
      }

      try {
        // Use Drizzle ORM to find the balance by address
        const balanceRecord = await fastify.db
          .select({
            cursor: max(usdcBalance.cursor),
            balance: usdcBalance.balance,
          })
          .from(usdcBalance)
          .where(eq(usdcBalance.address, address))
          .groupBy(usdcBalance.balance)
          .execute()

        const balance = balanceRecord[0]?.balance ?? '0'

        return reply.send({ balance })
      } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: 'Internal server error' })
      }
    },
  )
}
