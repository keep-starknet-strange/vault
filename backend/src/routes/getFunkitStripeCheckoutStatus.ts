import type { FastifyInstance } from 'fastify'

import { FUNKIT_API_BASE_URL } from '@/constants/funkit'

export function getFunkitStripeCheckoutStatus(fastify: FastifyInstance, funkitApiKey: string) {
  fastify.get(
    '/get_funkit_stripe_checkout_status',

    async (request, reply) => {
      const { funkitDepositAddress } = request.query as {
        funkitDepositAddress: string
      }

      if (!funkitDepositAddress) {
        return reply.status(400).send({ message: 'funkitDepositAddress is required.' })
      }
      try {
        const checkoutRes = await fetch(`${FUNKIT_API_BASE_URL}/checkout/${funkitDepositAddress}`, {
          headers: {
            'X-Api-Key': funkitApiKey,
          },
        })
        const checkoutItem = (await checkoutRes.json()) as any
        if (!checkoutItem || checkoutItem?.errorMsg) {
          return reply.status(500).send({ message: 'Failed to get a funkit checkout.' })
        }
        return reply.send({
          state: checkoutItem.state,
        })
      } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: 'Internal server error' })
      }
    },
  )
}
