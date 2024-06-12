import type { FastifyInstance } from 'fastify'
import { type Account } from 'starknet'

import { Entrypoint } from '@/constants/contracts'

interface ExecuteFromOutsideBody {
  address: string
  calldata: string[]
}

export function getExecuteFromOutsideRoute(fastify: FastifyInstance, deployer: Account) {
  fastify.post<{
    Body: ExecuteFromOutsideBody
  }>(
    '/execute_from_outside',

    {
      schema: {
        body: {
          type: 'object',
          required: ['address', 'calldata'],
          properties: {
            address: { type: 'string', pattern: '^0x0[0-9a-fA-F]{63}$' },
            calldata: {
              type: 'array',
              items: { type: 'string', pattern: '^[0-9]{0,76}$' },
            },
          },
        },
      },
    },

    async (request, reply) => {
      try {
        const { address, calldata } = request.body
        if (!calldata.length) {
          return reply.code(500).send({
            message: 'Empty calldata.',
          })
        }

        const { transaction_hash } = await deployer.execute({
          contractAddress: address,
          calldata,
          entrypoint: Entrypoint.EXECUTE_FROM_OUTSIDE,
        })

        fastify.log.info('Executing from outside for: ', address, ' with tx hash: ', transaction_hash)

        if (!transaction_hash) {
          return reply.code(500).send({
            message: 'Error in executing from outside.',
          })
        }

        return reply.code(200).send({
          transaction_hash,
        })
      } catch (error) {
        fastify.log.error(error)
        return reply.code(500).send({ message: 'Internal Server Error' })
      }
    },
  )
}
