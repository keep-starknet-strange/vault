import elliptic from 'elliptic'
import { constants, hash, shortString, typedData, uint256 } from 'starknet'

export const TESTNET_USDC = '0x053b40A647CEDfca6cA84f542A0fe36736031905A9639a7f19A3C1e66bFd5080'

export function signOutsideUsdcTransfer(
  signer: string,
  calls: { amount: number; recipient: string }[],
  nonce: number,
  usdc: string,
) {
  const caller = shortString.encodeShortString('ANY_CALLER')
  const Calls = calls.map((call) => {
    return {
      To: usdc,
      Selector: 'transfer',
      Calldata: [call.recipient, call.amount, 0],
    }
  })

  const executeAfter = 0
  const executeBefore = 999_999_999_999
  const data = {
    types: {
      StarknetDomain: [
        { name: 'name', type: 'shortstring' },
        { name: 'version', type: 'shortstring' },
        { name: 'chainId', type: 'shortstring' },
        { name: 'revision', type: 'shortstring' },
      ],
      OutsideExecution: [
        { name: 'Caller', type: 'ContractAddress' },
        { name: 'Nonce', type: 'felt' },
        { name: 'Execute After', type: 'u128' },
        { name: 'Execute Before', type: 'u128' },
        { name: 'Calls', type: 'Call*' },
      ],
      Call: [
        { name: 'To', type: 'ContractAddress' },
        { name: 'Selector', type: 'selector' },
        { name: 'Calldata', type: 'felt*' },
      ],
    },
    primaryType: 'OutsideExecution',
    domain: {
      name: 'Account.execute_from_outside',
      version: '0x2',
      chainId: constants.StarknetChainId.SN_SEPOLIA,
      revision: '1',
    },
    message: {
      Caller: caller,
      Nonce: nonce,
      'Execute After': executeAfter,
      'Execute Before': executeBefore,
      Calls,
    },
  }

  const ec = new elliptic.ec('p256')
  const msg = typedData.getMessageHash(data, signer).slice(2)

  // Generate key pair from private key
  const keyPair = ec.keyFromPrivate('1234')

  // Sign the message hash
  const signature = keyPair.sign(msg, 'hex')

  return [
    caller,
    nonce,
    executeAfter,
    executeBefore,
    Calls.map((call) => {
      return {
        to: call.To,
        selector: hash.getSelectorFromName(call.Selector),
        calldata: call.Calldata,
      }
    }),
    4,
    uint256.bnToUint256('0x' + signature.r.toString(16)),
    uint256.bnToUint256('0x' + signature.s.toString(16)),
  ]
}
