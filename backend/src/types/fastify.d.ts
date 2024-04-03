// src/types/fastify.d.ts or wherever your custom types are defined
import 'fastify';
import { Pool, PoolClient, QueryResult } from 'pg';

declare module 'fastify' {
  interface FastifyInstance {
    pg: {
      pool: Pool; // Access to the pool
      connect: () => Promise<PoolClient>; // Method to connect to the pool
      // Added direct query method similar to PoolClient.query
      query: <T>(text: string, params?: any[]) => Promise<QueryResult<T>>;
    };
  }
}
