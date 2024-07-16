import { getCheckoutQuote, getStripeBuyQuote } from '@funkit/api-base'
import type { FastifyInstance } from 'fastify'
import { getChecksumAddress } from 'starknet'

import { FUNKIT_STARKNET_CHAIN_ID, FUNKIT_STRIPE_SOURCE_CURRENCY, TOKEN_INFO } from '@/constants/funkit'
import { getBooleanFromString, pickSourceAssetForCheckout, roundUpToFiveDecimalPlaces } from '@/utils/funkit'

import { addressRegex } from '.'
interface GetQuoteQuery {
  address: string
  tokenAmount: number
  isNy: boolean
  isEu: boolean
}

export function getFunkitStripeCheckoutQuote(fastify: FastifyInstance, funkitApiKey: string) {
  fastify.get(
    '/get_funkit_stripe_checkout_quote',

    async (request, reply) => {
      const { address, tokenAmount, isNy, isEu } = request.query as GetQuoteQuery

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

      if (isEu == null) {
        return reply.status(400).send({ message: 'isEu is a required boolean.' })
      }

      try {
        // 1 - Generate the funkit checkout quote
        const pickedSourceAsset = pickSourceAssetForCheckout(getBooleanFromString(isEu), getBooleanFromString(isNy))
        const normalizedRecipientAddress = getChecksumAddress(address)
        const baseQuote = await getCheckoutQuote({
          fromChainId: pickedSourceAsset.networkId,
          fromTokenAddress: pickedSourceAsset.address as `0x${string}`,
          fromTokenDecimals: pickedSourceAsset.decimals,
          toChainId: FUNKIT_STARKNET_CHAIN_ID,
          toTokenAddress: TOKEN_INFO.STARKNET_USDC.address as `0x${string}`,
          toTokenDecimals: TOKEN_INFO.STARKNET_USDC.decimals,
          toTokenAmount: Number(tokenAmount),
          expirationTimestampMs: 1_800_000, // 30 minutes
          apiKey: funkitApiKey,
          sponsorInitialTransferGasLimit: '0',
          recipientAddr: normalizedRecipientAddress as `0x${string}`,
          userId: normalizedRecipientAddress,
          needsRefuel: false,
        })
        if (!baseQuote || !baseQuote.quoteId) {
          return reply.status(500).send({ message: 'Failed to get a funkit quote.' })
        }

        const estTotalFromAmount = roundUpToFiveDecimalPlaces(baseQuote.estTotalFromAmount)
        // 2 - Get the stripe quote based on the
        const stripeFullQuote = await getStripeBuyQuote({
          sourceCurrency: FUNKIT_STRIPE_SOURCE_CURRENCY,
          destinationCurrency: pickedSourceAsset.symbol,
          destinationNetwork: pickedSourceAsset.network,
          destinationAmount: estTotalFromAmount,
          apiKey: funkitApiKey,
          isSandbox: false,
        })
        const stripeQuote = stripeFullQuote?.destination_network_quotes?.[pickedSourceAsset.network]?.[0]
        if (!stripeQuote) {
          return reply.status(500).send({ message: 'Failed to get stripe quote.' })
        }
        const finalQuote = {
          quoteId: baseQuote.quoteId,
          estSubtotalUsd: baseQuote.estSubtotalUsd,
          paymentTokenChain: pickedSourceAsset.network,
          paymentTokenSymbol: pickedSourceAsset.symbol,
          paymentTokenAmount: estTotalFromAmount,
          networkFees: (Number(stripeQuote.fees.network_fee_monetary) + Number(baseQuote.estFeesUsd)).toFixed(2),
          cardFees: Number(stripeQuote.fees.transaction_fee_monetary).toFixed(2),
          totalUsd: Number(stripeQuote.source_total_amount).toFixed(2),
        }
        return reply.send(finalQuote)
      } catch (error) {
        console.error(error)
        return reply.status(500).send({ message: 'Internal server error' })
      }
    },
  )
}
