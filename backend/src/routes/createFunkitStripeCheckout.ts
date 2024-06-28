import type { FastifyInstance } from 'fastify'

import {
  FUNKIT_API_BASE_URL,
  FUNKIT_STRIPE_SOURCE_CURRENCY,
  POLYGON_NETWORK_NAME,
  SOURCE_OF_FUND_KEY,
} from '@/constants/funkit'
import {
  generateClientMetadata,
  generateRandomCheckoutSalt,
  pickSourceAssetForCheckout,
  stringifyWithBigIntSanitization,
} from '@/utils/funkit'

interface InitCheckoutBody {
  quoteId: string
  paymentTokenAmount: number
  estSubtotalUsd: number
  isNy: boolean
}

export function createFunkitStripeCheckout(fastify: FastifyInstance, funkitApiKey: string): void {
  fastify.post<{ Body: InitCheckoutBody }>('/create_funkit_stripe_checkout', async (request, reply) => {
    const { quoteId, paymentTokenAmount, estSubtotalUsd, isNy } = request.body as InitCheckoutBody
    if (!quoteId) {
      return reply.status(400).send({ message: 'quoteId is required.' })
    }

    if (!paymentTokenAmount) {
      return reply.status(400).send({ message: 'paymentTokenAmount is required.' })
    }

    if (!estSubtotalUsd) {
      return reply.status(400).send({ message: 'estSubtotalUsd is required.' })
    }

    if (isNy == null) {
      return reply.status(400).send({ message: 'isNy is a required boolean.' })
    }

    try {
      // 1 - Initialize the checkout and get a unique depositAddress
      const pickedSourceAsset = pickSourceAssetForCheckout(isNy)
      const body = {
        quoteId,
        sourceOfFund: SOURCE_OF_FUND_KEY,
        salt: generateRandomCheckoutSalt(),
        clientMetadata: generateClientMetadata({ pickedSourceAsset, estDollarValue: estSubtotalUsd }),
      }
      const fetchRes = await fetch(`${FUNKIT_API_BASE_URL}/checkout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': funkitApiKey,
        },
        body: stringifyWithBigIntSanitization(body),
      })
      const res = (await fetchRes.json()) as any
      const depositAddress = res?.depositAddr
      if (!depositAddress) {
        return reply.status(500).send({ message: 'Failed to start a funkit checkout.' })
      }

      // 2 - Generate stripe session
      const stripeSessionBody = {
        sourceCurrency: FUNKIT_STRIPE_SOURCE_CURRENCY,
        destinationAmount: paymentTokenAmount,
        destinationCurrencies: [pickedSourceAsset.symbol],
        destinationCurrency: pickedSourceAsset.symbol,
        destinationNetworks: [POLYGON_NETWORK_NAME],
        destinationNetwork: POLYGON_NETWORK_NAME,
        walletAddresses: {
          [POLYGON_NETWORK_NAME]: depositAddress,
        },
      }
      const generateStripeRes = await fetch(`${FUNKIT_API_BASE_URL}/on-ramp/stripe-checkout`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': funkitApiKey,
        },
        body: stringifyWithBigIntSanitization(stripeSessionBody),
      })
      const stripeSession = (await generateStripeRes.json()) as any
      if (!stripeSession || !stripeSession.id || !stripeSession.redirect_url) {
        return reply.status(500).send({ message: 'Failed to start a stripe checkout session.' })
      }
      return reply.send({
        stripeCheckoutId: stripeSession.id,
        stripeRedirectUrl: stripeSession.redirect_url,
        funkitDepositAddress: depositAddress,
      })
    } catch (error) {
      console.error('Failed to start a checkout:', error)
      return reply.status(500).send({ message: 'Failed to start a checkout.' })
    }
  })
}
