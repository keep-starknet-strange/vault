import { createStripeBuySession, initializeCheckout } from '@funkit/api-base'
import type { FastifyInstance } from 'fastify'

import { FUNKIT_STRIPE_SOURCE_CURRENCY, SOURCE_OF_FUND_KEY } from '@/constants/funkit'
import { generateClientMetadata, getBooleanFromString, pickSourceAssetForCheckout } from '@/utils/funkit'

interface InitCheckoutBody {
  quoteId: string
  paymentTokenAmount: number
  estSubtotalUsd: number
  isNy: boolean
  isEu: boolean
}

export function createFunkitStripeCheckout(fastify: FastifyInstance, funkitApiKey: string): void {
  fastify.post<{ Body: InitCheckoutBody }>('/create_funkit_stripe_checkout', async (request, reply) => {
    const { quoteId, paymentTokenAmount, estSubtotalUsd, isEu, isNy } = request.body as InitCheckoutBody
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

    if (isEu == null) {
      return reply.status(400).send({ message: 'isEu is a required boolean.' })
    }

    try {
      // 1 - Initialize the checkout and get a unique depositAddress
      const pickedSourceAsset = pickSourceAssetForCheckout(getBooleanFromString(isEu), getBooleanFromString(isNy))
      const depositAddress = await initializeCheckout({
        userOp: null,
        quoteId,
        sourceOfFund: SOURCE_OF_FUND_KEY,
        clientMetadata: generateClientMetadata({ pickedSourceAsset, estDollarValue: estSubtotalUsd }),
        apiKey: funkitApiKey,
      })
      if (!depositAddress) {
        return reply.status(500).send({ message: 'Failed to start a funkit checkout.' })
      }
      // 2 - Generate stripe session
      const stripeSession = await createStripeBuySession({
        apiKey: funkitApiKey,
        sourceCurrency: FUNKIT_STRIPE_SOURCE_CURRENCY,
        destinationAmount: paymentTokenAmount,
        destinationCurrency: pickedSourceAsset.symbol,
        destinationNetwork: pickedSourceAsset.network,
        walletAddress: depositAddress,
        isSandbox: false,
      })
      if (!stripeSession || !stripeSession.id || !stripeSession.redirect_url) {
        return reply.status(500).send({ message: 'Failed to start a stripe checkout session.' })
      }
      return reply.send({
        stripeCheckoutId: stripeSession.id,
        stripeRedirectUrl: stripeSession.redirect_url,
        funkitDepositAddress: depositAddress,
      })
    } catch (error: any) {
      console.error('Failed to start a checkout:', error)
      return reply.status(500).send({ message: 'Failed to start a checkout.' })
    }
  })
}
