import { toHex } from 'viem'

import { POLYGON_CHAIN_ID, TOKEN_INFO } from '@/constants/funkit'

function randomBytes(length: number) {
  const bytes = new Uint8Array(length)
  for (let i = 0; i < length; i++) {
    bytes[i] = Math.floor(Math.random() * 256)
  }
  return toHex(bytes)
}

export function generateRandomCheckoutSalt() {
  return BigInt(randomBytes(32))
}

export function stringifyWithBigIntSanitization(object: any) {
  return JSON.stringify(
    object,
    (_, value) => (typeof value === 'bigint' ? toHex(value) : value), // return everything else unchanged
  )
}

export function roundUpToFiveDecimalPlaces(inputNumber: string) {
  // Using toFixed to round up to 5 decimal places
  const multiplier = 10 ** 5
  const roundedString = (Math.ceil(parseFloat(inputNumber) * multiplier) / multiplier).toFixed(5)
  // Converting the rounded string back to a number
  const roundedNumber = parseFloat(roundedString)
  return roundedNumber
}

export function pickSourceAssetForCheckout(isNy: boolean) {
  return isNy ? TOKEN_INFO.POLYGON_MATIC : TOKEN_INFO.POLYGON_USDC
}

// To be compliant with existing funkit SDK -- can be ignored
export function generateClientMetadata({
  pickedSourceAsset,
  estDollarValue,
}: {
  pickedSourceAsset: any
  estDollarValue: number
}) {
  return {
    id: generateRandomCheckoutSalt().toString(),
    startTimestampMs: Date.now(),
    draftDollarValue: estDollarValue.toFixed(5),
    finalDollarValue: estDollarValue.toFixed(5),
    latestQuote: {},
    depositAddress: null,
    initSettings: {},
    isFastForwarded: false,
    selectedSourceAssetInfo: {
      address: pickedSourceAsset.address,
      chainId: POLYGON_CHAIN_ID,
      symbol: pickedSourceAsset.symbol.toUpperCase(),
    },
    selectedPaymentMethodInfo: {
      paymentMethod: 'card',
      title: 'Debit or Credit',
      description: '',
      meta: {},
    },
  }
}
