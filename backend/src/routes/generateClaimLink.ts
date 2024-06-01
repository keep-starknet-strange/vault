import type { FastifyInstance } from 'fastify'

import * as schema from '../db/schema'

interface ClaimRequestBody {
  amount: string
  nonce: number
  address: string
  signature: string[]
}

export function getGenerateClaimLinkRoute(fastify: FastifyInstance): void {
  fastify.post<{ Body: ClaimRequestBody }>(
    '/generate_claim_link',

    {
      schema: {
        body: {
          type: 'object',
          required: ['amount', 'nonce', 'address', 'signature'],
          properties: {
            amount: { type: 'string', pattern: '^0x[0-9a-fA-F]{1,64}$' },
            nonce: { type: 'integer' },
            address: { type: 'string', pattern: '^0x0[0-9a-fA-F]{63}$' },
            signature: {
              type: 'array',
              items: { type: 'string', pattern: '^0x[0-9a-fA-F]{64}$' },
            },
          },
        },
      },
    },

    async (request, reply) => {
      const { amount, nonce, signature, address } = request.body

      // Validate the input
      if (/^0x[0]{1,64}$/.test(amount)) {
        return reply.status(400).send({ message: "Amount can't be zero." })
      }

      if (!signature.length) {
        return reply.status(400).send({ message: 'Missing signature.' })
      }

      // Generate the claim link
      try {
        const req = await fastify.db
          .insert(schema.claims)
          .values({ amount, signature, address, nonce })
          .onConflictDoNothing()
          .returning()

        if (!req.length) {
          return reply.status(400).send({ message: 'Nonce already used.' })
        }

        const claimToken = req[0].id

        const claimLink = `https://vlt.finance/claim?token=${claimToken}`
        return reply.send({ claimLink })
      } catch (error) {
        console.error('Failed to generate claim link:', error)
        return reply.status(500).send({ message: 'Failed to generate claim link.' })
      }
    },
  )
}
