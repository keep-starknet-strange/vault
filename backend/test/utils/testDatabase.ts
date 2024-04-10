import { exec } from 'child_process';
import { promisify } from 'util';
import postgres from 'postgres'; // If direct usage is needed
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import { drizzle, PostgresJsDatabase } from 'drizzle-orm/postgres-js'; // Adjust imports based on actual usage
import * as schema from '../../src/db/schema'; // Adjust based on actual file structure

const execAsync = promisify(exec);

const createDatabase = async (dbName: string) => {
  await execAsync(`createdb ${dbName}`);
};

const dropDatabase = async (dbName: string) => {
  await execAsync(`dropdb ${dbName}`);
};

// Assume connectionString is the full connection string to your database
const runMigrations = async (connectionString: string) => {
  // Initialize the database object with Drizzle
  const sql = postgres(connectionString);
  const db: PostgresJsDatabase<typeof schema> = drizzle(sql, { schema });

  // Assuming migrate function is part of your migrations setup
  // and it can accept a database object of type PostgresJsDatabase
  await migrate(db, { migrationsFolder: '../../../src/db/migrations' });
};

export { createDatabase, dropDatabase, runMigrations };
