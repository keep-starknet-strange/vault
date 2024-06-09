import { postgres } from './deps.ts'

const sql = postgres(Deno.env.get('DATABASE_URL') ?? '')

export default sql
