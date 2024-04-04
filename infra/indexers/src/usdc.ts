import { ec, hash } from "./deps.ts";

export const USDC_ADDRESS =
  "0x53c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8";

export const USDC_DECIMALS = 6;

/**
 * Computes the storage location of the balance of an address.
 *
 * @param address The address.
 * @returns The storage location.
 */
export function balanceStorageLocation(address: string) {
  const addressBound = 2n ** 251n;

  let hashed = hash.getSelectorFromName("ERC20_balances");
  hashed = ec.starkCurve.pedersen(hashed, address);

  let location = BigInt(hashed);
  if (location >= addressBound) {
    location -= addressBound;
  }

  return location;
}
