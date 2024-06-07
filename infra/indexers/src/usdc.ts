import { ec, hash } from "./deps.ts";

export const USDC_ADDRESS =
  "0x07ab0b8855a61f480b4423c46c32fa7c553f0aac3531bbddaa282d86244f7a23";

/**
 * Computes the storage location of the balance of an address.
 *
 * @param address The address.
 * @returns The storage location.
 */
export function balanceStorageLocation(address: string): bigint {
  const addressBound = 2n ** 251n;

  let hashed = hash.getSelectorFromName("balances");
  hashed = ec.starkCurve.pedersen(hashed, address);

  let location = BigInt(hashed);
  if (location >= addressBound) {
    location -= addressBound;
  }

  return location;
}
