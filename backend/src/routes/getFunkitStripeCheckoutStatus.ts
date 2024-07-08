import { getCheckoutByDepositAddress } from '@funkit/api-base'
import type { FastifyInstance } from 'fastify'

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
        const checkoutItem = await getCheckoutByDepositAddress({
          depositAddress: funkitDepositAddress as `0x${string}`,
          apiKey: funkitApiKey,
        })
        if (!checkoutItem || !checkoutItem?.depositAddr) {
          return reply.status(500).send({ message: 'Failed to get a funkit checkout.' })
        }
        return reply.send({
          state: checkoutItem.state,
        })
      } catch (error: any) {
        if (error?.message?.includes('InvalidParameterError')) {
          return reply.status(500).send({ message: 'Failed to get a funkit checkout.' })
        }
        return reply.status(500).send({ message: 'Internal server error' })
      }
    },
  )
}
