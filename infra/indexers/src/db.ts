import { pg } from './deps.ts'

const { Client } = pg
const client = new Client({ connectionString: Deno.env.get('DATABASE_URL') })

export default client
