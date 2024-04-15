import type { FastifyInstance } from 'fastify';
import * as schema from '../db/schema';

// Define an interface for the request body
interface RegisterRequestBody {
  phone_number: string;
  address: string;
  first_name: string;
  last_name: string;
}

export function getRegisterRoute(fastify: FastifyInstance) {
  fastify.post<{
    Body: RegisterRequestBody;
  }>(
    '/register',
    {
      schema: {
        body: {
          type: 'object',
          required: ['phone_number', 'address', 'first_name', 'last_name'],
          properties: {
            phone_number: { type: 'string', pattern: '^\\+[1-9]\\d{1,14}$' },
            address: { type: 'string', pattern: '^0x0[0-9a-fA-F]{63}$' },
            first_name: { type: 'string', pattern: '^[A-Za-z]{1,20}$' },
            last_name: { type: 'string', pattern: '^[A-Za-z]{1,20}$' },
          },
        },
      },
    },
    async (request, reply) => {
      const { phone_number, address, first_name, last_name } = request.body;

      try {
        await fastify.db.insert(schema.registration).values({
          phone_number,
          address,
          first_name,
          last_name,
        });

        return reply.code(200).send(true);
        // biome-ignore lint: has to be typed any or unknown otherwise typescript cries
      } catch (error: any) {
        fastify.log.error(error);
        if (error.code === '23505') {
          return reply.code(409).send({
            message: 'A user with the given phone number already exists.',
          });
        }
        return reply.code(500).send({ message: 'Internal server error' });
      }
    },
  );
}
