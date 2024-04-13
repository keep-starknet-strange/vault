import { eq } from "drizzle-orm/pg-core/expressions";
import type { FastifyInstance } from "fastify";

import { usdcBalance } from "@/db/schema";

const addressRegex = /^0x0[0-9a-fA-F]{63}$/;

export function getBalanceRoute(fastify: FastifyInstance) {
  fastify.get("/get_balance", async (request, reply) => {
    const { address } = request.query as { address?: string };
    if (!address) {
      return reply.status(400).send({ error: "Address is required." });
    }
    // Validate address format
    if (!addressRegex.test(address)) {
      return reply.status(400).send({ error: "Invalid address format." });
    }

    try {
      // Use Drizzle ORM to find the balance by address
      let balanceRecord = await fastify.db.query.usdcBalance
        .findFirst({ where: eq(usdcBalance.address, address) })
        .execute();
      if (!balanceRecord) {
        balanceRecord = { balance: "0" };
      }

      return reply.send({ balance: balanceRecord.balance });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ error: "Internal server error" });
    }
  });
}
