import { FastifyInstance, FastifyRequest, FastifyReply } from "fastify";

export function declareRoutes(fastify: FastifyInstance) {
  fastify.get(
    "/status",
    async function handler(_request: FastifyRequest, _reply: FastifyReply) {
      return handleGetStatus();
    }
  );
}

function handleGetStatus() {
  return { status: "OK" };
}
