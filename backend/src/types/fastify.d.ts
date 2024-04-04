import { Database } from "../db/plugin";
import type { db } from "./db";
import type { Redis } from "./utils";

declare module "fastify" {
  interface FastifyInstance {
    db: Database;
  }
}
