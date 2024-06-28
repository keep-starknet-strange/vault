import { hash } from 'starknet'

import { BLANK_ACCOUNT_CLASS_HASH, SN_CHAIN_ID, VAULT_FACTORY_ADDRESSES } from '@/constants/contracts'

import { hashPhoneNumber } from './phoneNumber'

export function computeAddress(phoneNumber: string) {
  return hash.calculateContractAddressFromHash(
    hashPhoneNumber(phoneNumber),
    BLANK_ACCOUNT_CLASS_HASH,
    [],
    VAULT_FACTORY_ADDRESSES[SN_CHAIN_ID],
  )
}
