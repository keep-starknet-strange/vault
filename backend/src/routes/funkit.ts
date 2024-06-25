import Big from 'big.js'
import type { FastifyInstance } from 'fastify'
import { Address } from 'viem'

import {
  FUNKIT_API_BASE_URL,
  FUNKIT_API_KEY,
  FUNKIT_STARKNET_CHAIN_ID,
  FUNKIT_STRIPE_SOURCE_CURRENCY,
  POLYGON_CHAIN_ID,
  POLYGON_NETWORK_NAME,
  SOURCE_OF_FUND_KEY,
  TOKEN_INFO,
} from '@/constants/funkit'
import {
  generateClientMetadata,
  generateRandomCheckoutSalt,
  pickSourceAssetForCheckout,
  roundUpToFiveDecimalPlaces,
  stringifyWithBigIntSanitization,
} from '@/utils/funkit'

import { addressRegex } from '.'

interface CheckoutQuote {
  quoteId: string
  estTotalFromAmountBaseUnit: string
  estSubtotalFromAmountBaseUnit: string
  estFeesFromAmountBaseUnit: string
  fromTokenAddress: Address
  estFeesUsd: number
  estSubtotalUsd: number
  estTotalUsd: number
  estCheckoutTimeMs: number
}

export function getFunkitStripeCheckoutQuote(fastify: FastifyInstance) {
  fastify.get(
    '/get_funkit_stripe_checkout_quote',

    async (request, reply) => {
      const { address, tokenAmount, isNy } = request.query as { address: string; tokenAmount: number; isNy: boolean }

      if (!address) {
        return reply.status(400).send({ message: 'Address is required.' })
      }

      if (!addressRegex.test(address)) {
        return reply.status(400).send({ message: 'Invalid address format.' })
      }

      if (!tokenAmount) {
        return reply.status(400).send({ message: 'Token amount is required.' })
      }

      if (isNy == null) {
        return reply.status(400).send({ message: 'isNy is a required boolean.' })
      }

      try {
        // 1 - Generate the funkit checkout quote
        const toMultiplier = 10 ** TOKEN_INFO.STARKNET_USDC.decimals
        const toAmountBaseUnitBI = BigInt(Math.floor(tokenAmount * toMultiplier))
        const pickedSourceAsset = pickSourceAssetForCheckout(isNy)
        const queryParams = {
          fromChainId: POLYGON_CHAIN_ID,
          fromTokenAddress: pickedSourceAsset.address,
          toChainId: FUNKIT_STARKNET_CHAIN_ID,
          toTokenAddress: TOKEN_INFO.STARKNET_USDC.address,
          toAmountBaseUnit: toAmountBaseUnitBI.toString(),
          recipientAddr: address,
          // 1 hour from now
          checkoutExpirationTimestampSeconds: Math.round((Date.now() + 3600000) / 1000).toString(),
        }
        const searchParams = new URLSearchParams(queryParams)
        const fetchRes = await fetch(`${FUNKIT_API_BASE_URL}/checkout/quote?${searchParams}`, {
          headers: {
            'X-Api-Key': FUNKIT_API_KEY,
          },
        })
        const quoteRes = (await fetchRes.json()) as CheckoutQuote
        if (!quoteRes || !quoteRes.quoteId) {
          return reply.status(500).send({ message: 'Failed to get a funkit quote.' })
        }

        const fromMultiplier = 10 ** pickedSourceAsset.decimals
        const estTotalFromAmount = roundUpToFiveDecimalPlaces(
          new Big(quoteRes.estTotalFromAmountBaseUnit).div(fromMultiplier).toString(),
        ).toString()

        // 2 - Get the stripe quote based on the
        const stripeQuoteParams = {
          sourceCurrency: FUNKIT_STRIPE_SOURCE_CURRENCY,
          destinationCurrencies: pickedSourceAsset.symbol,
          destinationNetworks: POLYGON_NETWORK_NAME,
          destinationAmount: estTotalFromAmount,
        }
        const stripeQuoteSearchParams = new URLSearchParams(stripeQuoteParams)
        const stripeQuoteRes = await fetch(
          `${FUNKIT_API_BASE_URL}/on-ramp/stripe-buy-quote?${stripeQuoteSearchParams}`,
          {
            headers: {
              'X-Api-Key': FUNKIT_API_KEY,
            },
          },
        )
        const stripeQuote = (await stripeQuoteRes.json()) as any
        const stripePolygonQuote = stripeQuote?.destination_network_quotes?.polygon?.[0]
        if (!stripePolygonQuote) {
          return reply.status(500).send({ message: 'Failed to get stripe quote.' })
        }
        const finalQuote = {
          quoteId: quoteRes.quoteId,
          estSubtotalUsd: quoteRes.estSubtotalUsd,
          paymentTokenAmount: estTotalFromAmount,
          networkFees: (Number(stripePolygonQuote.fees.network_fee_monetary) + Number(quoteRes.estFeesUsd)).toFixed(2),
          cardFees: Number(stripePolygonQuote.fees.transaction_fee_monetary).toFixed(2),
          totalUsd: Number(stripePolygonQuote.source_total_amount).toFixed(2),
        }
        return reply.send(finalQuote)
      } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: 'Internal server error' })
      }
    },
  )
}

interface InitCheckoutBody {
  quoteId: string
  paymentTokenAmount: number
  estSubtotalUsd: number
  isNy: boolean
}

export function createFunkitStripeCheckout(fastify: FastifyInstance): void {
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
          'X-Api-Key': FUNKIT_API_KEY,
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
          'X-Api-Key': FUNKIT_API_KEY,
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

export function getFunkitStripeCheckoutStatus(fastify: FastifyInstance) {
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
            'X-Api-Key': FUNKIT_API_KEY,
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
