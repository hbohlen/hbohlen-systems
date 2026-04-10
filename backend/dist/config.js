import 'dotenv/config';
import { homedir } from 'os';
import { join } from 'path';
export const config = {
    port: parseInt(process.env.PORT || '3000', 10),
    authFilePath: process.env.AUTH_FILE_PATH || join(homedir(), '.pi', 'agent', 'auth.json'),
    nodeEnv: process.env.NODE_ENV || 'development',
};
