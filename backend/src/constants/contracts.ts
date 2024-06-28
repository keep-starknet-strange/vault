import { constants } from 'starknet'

type SupportedChainId = Exclude<constants.StarknetChainId, typeof constants.StarknetChainId.SN_GOERLI>

type AddressesMap = Record<SupportedChainId, string>

export const BLANK_ACCOUNT_CLASS_HASH = '0x1fa186ff7ea06307ded0baa1eb7648afc43618b92084da1110a9c0bd2b6bf56'

export enum Entrypoint {
  DEPLOY_ACCOUNT = 'deploy_account',
  EXECUTE_FROM_OUTSIDE = 'execute_from_outside_v2',
}

export const VAULT_FACTORY_ADDRESSES: AddressesMap = {
  [constants.StarknetChainId.SN_MAIN]: '0x410da9af28e654fa93354430841ce7c5f0c2c17cc92971fb23d3d4f826d9834',
  [constants.StarknetChainId.SN_SEPOLIA]: '0x33498f0d9e6ebef71b3d8dfa56501388cfe5ce96cba81503cd8572be92bd77c',
}

export const DEFAULT_NETWORK_NAME = constants.NetworkName.SN_SEPOLIA

// eslint-disable-next-line import/no-unused-modules
export const SN_CHAIN_ID = (constants.StarknetChainId[(process.env.SN_NETWORK ?? '') as constants.NetworkName] ??
  constants.StarknetChainId[DEFAULT_NETWORK_NAME]) as SupportedChainId

const NODE_URLS = {
  [constants.StarknetChainId.SN_MAIN]: (apiKey: string) => `https://rpc.nethermind.io/mainnet-juno/?apikey=${apiKey}`,
  [constants.StarknetChainId.SN_SEPOLIA]: (apiKey: string) =>
    `https://rpc.nethermind.io/sepolia-juno/?apikey=${apiKey}`,
}

export const NODE_URL = NODE_URLS[SN_CHAIN_ID](process.env.NODE_API_KEY!)
