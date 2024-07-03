export const FUNKIT_API_BASE_URL = 'https://api.fun.xyz/v1'
export const FUNKIT_STARKNET_CHAIN_ID = '23448594291968334'
export const POLYGON_CHAIN_ID = '137'
export const POLYGON_NETWORK_NAME = 'polygon'
export const SOURCE_OF_FUND_KEY = 'card|stripe'
export const FUNKIT_STRIPE_SOURCE_CURRENCY = 'usd'

const STARKNET_USDC_ADDRESS = '0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8'
const STARKNET_USDC_DECIMALS = 6
const POLYGON_MATIC_ADDRESS = '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
const POLYGON_MATIC_DECIMALS = 18
const POLYGON_USDC_ADDRESS = '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359'
const POLYGON_USDC_DECIMALS = 6

export const TOKEN_INFO = {
  STARKNET_USDC: {
    address: STARKNET_USDC_ADDRESS,
    decimals: STARKNET_USDC_DECIMALS,
    symbol: 'usdc',
  },
  POLYGON_MATIC: {
    address: POLYGON_MATIC_ADDRESS,
    decimals: POLYGON_MATIC_DECIMALS,
    symbol: 'matic',
  },
  POLYGON_USDC: {
    address: POLYGON_USDC_ADDRESS,
    decimals: POLYGON_USDC_DECIMALS,
    symbol: 'usdc',
  },
}
