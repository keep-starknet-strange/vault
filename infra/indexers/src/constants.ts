import { constants } from './deps.ts'

export const STORAGE_ADDRESS_BOUND = 2n ** 251n

type SupportedChainId = Exclude<constants.StarknetChainId, typeof constants.StarknetChainId.SN_GOERLI>

type AddressesMap = Record<SupportedChainId, string>

export const USDC_ADDRESSES: AddressesMap = {
  [constants.StarknetChainId.SN_MAIN]: '0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8',
  [constants.StarknetChainId.SN_SEPOLIA]: '0x07ab0b8855a61f480b4423c46c32fa7c553f0aac3531bbddaa282d86244f7a23',
}

const DEFAULT_NETWORK_NAME = constants.NetworkName.SN_SEPOLIA

export const SN_CHAIN_ID =
  (constants.StarknetChainId[(Deno.env.get('SN_NETWORK') ?? '') as constants.NetworkName] ??
  constants.StarknetChainId[DEFAULT_NETWORK_NAME]) as SupportedChainId

export const STREAM_URLS = {
  [constants.StarknetChainId.SN_MAIN]: 'https://mainnet.starknet.a5a.ch',
  [constants.StarknetChainId.SN_SEPOLIA]: 'https://sepolia.starknet.a5a.ch',
}

export const STARTING_BLOCK = Number(Deno.env.get('STARTING_BLOCK')) ?? 0

export const BALANCES_VAR_NAMES = {
  [constants.StarknetChainId.SN_MAIN]: 'ERC20_balances',
  [constants.StarknetChainId.SN_SEPOLIA]: 'balances',
}
