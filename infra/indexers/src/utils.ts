import { STORAGE_ADDRESS_BOUND } from './constants.ts'
import { ec, hash } from './deps.ts'

/**
 * Computes the storage location of the balance of an address.
 *
 * @param address The address.
 * @param address The name of the slot.
 * @returns The storage location.
 */
export function getStorageLocation(address: string, name: string): bigint {
  const hashedName = hash.getSelectorFromName(name)
  const location = BigInt(ec.starkCurve.pedersen(hashedName, address))

  return location >= STORAGE_ADDRESS_BOUND ? location - STORAGE_ADDRESS_BOUND : location
}
