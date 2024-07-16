export const FUNKIT_STARKNET_CHAIN_ID = '23448594291968334'
export const SOURCE_OF_FUND_KEY = 'card|stripe'
export const FUNKIT_STRIPE_SOURCE_CURRENCY = 'usd'

export const TOKEN_INFO = {
  STARKNET_USDC: {
    address: '0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8',
    decimals: 6,
    symbol: 'usdc',
    network: 'starknet',
    networkId: FUNKIT_STARKNET_CHAIN_ID,
  },
  ETHEREUM_ETH: {
    address: '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
    decimals: 18,
    symbol: 'eth',
    network: 'ethereum',
    networkId: '1',
  },
  POLYGON_MATIC: {
    address: '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
    decimals: 18,
    symbol: 'matic',
    network: 'polygon',
    networkId: '137',
  },
  POLYGON_USDC: {
    address: '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359',
    decimals: 6,
    symbol: 'usdc',
    network: 'polygon',
    networkId: '137',
  },
}
