import dotenv from 'dotenv';

import { type AppConfiguration, buildAndStartApp } from '@/app';

dotenv.config();

console.log(process.env.DATABASE_URL);
const config: AppConfiguration = {
  database: {
    connectionString: process.env.DATABASE_URL || 'postgres://localhost:5432/postgres',
  },
  app: {
    port: Number.parseInt(process.env.PORT || '8080'),
  },
};

buildAndStartApp(config);
