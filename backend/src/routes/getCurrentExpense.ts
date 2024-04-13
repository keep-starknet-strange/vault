import { eq, and, gte } from "drizzle-orm/pg-core/expressions";
import type { FastifyInstance } from "fastify";

import { usdcBalance, usdcTransfer } from "@/db/schema";

const addressRegex = /^0x0[0-9a-fA-F]{63}$/;

export function getCurrentExpenseRoute(fastify: FastifyInstance) {
  fastify.get("/get_current_expense", async (request, reply) => {
    const { address } = request.query as { address?: string };
    
    if (!address) {
      return reply.status(400).send({ error: "Address is required." });
    }
    // Validate address format
    if (!addressRegex.test(address)) {
      return reply.status(400).send({ error: "Invalid address format." });
    }

    try {
      // Get the current date
      const currentDate = new Date();

      // Calculate the date 7 days ago
      const sevenDaysAgo = new Date(currentDate);
      sevenDaysAgo.setDate(currentDate.getDate() - 7);
      // Use Drizzle ORM to find expense by address
      let expenses = await fastify.db.query.usdcTransfer.findMany({
        where: and(
            eq(usdcTransfer.fromAddress, address),
            gte(usdcTransfer.createdAt, sevenDaysAgo)
        )
    }).execute();

      let totalAmount = 0
      for(let i = 0; i < expenses.length; i++){
        totalAmount += Number(expenses[i].amount)
      }

      return reply.send({ cumulated_expense: `0x${totalAmount.toString(16)}` });
    } catch (error) {
      console.error(error);
      return reply.status(500).send({ error: "Internal server error" });
    }
  });
}
