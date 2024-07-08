import { TOKEN_INFO } from '@/constants/funkit'

export function roundUpToFiveDecimalPlaces(inputNumber: string) {
  // Using toFixed to round up to 5 decimal places
  const multiplier = 10 ** 5
  const roundedString = (Math.ceil(parseFloat(inputNumber) * multiplier) / multiplier).toFixed(5)
  // Converting the rounded string back to a number
  const roundedNumber = parseFloat(roundedString)
  return roundedNumber
}

export function pickSourceAssetForCheckout(isEu: boolean, isNy: boolean) {
  return isEu ? TOKEN_INFO.ETHEREUM_ETH : isNy ? TOKEN_INFO.POLYGON_MATIC : TOKEN_INFO.POLYGON_USDC
}

export function getBooleanFromString(value: string | boolean) {
  return typeof value === 'boolean' ? value : value.toLowerCase() === 'true'
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
    id: Math.random(),
    startTimestampMs: Date.now(),
    draftDollarValue: estDollarValue.toFixed(5),
    finalDollarValue: estDollarValue.toFixed(5),
    latestQuote: {},
    depositAddress: null,
    initSettings: {},
    isFastForwarded: false,
    selectedSourceAssetInfo: {
      address: pickedSourceAsset.address,
      chainId: pickedSourceAsset.networkId,
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
