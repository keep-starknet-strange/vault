import { hash, shortString } from 'starknet'

export function hashPhoneNumber(phoneNumber: string) {
  return hash.starknetKeccak(shortString.encodeShortString(phoneNumber))
}
