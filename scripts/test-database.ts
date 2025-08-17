import { Pool } from 'pg';
import * as dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Load environment variables
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
dotenv.config({ path: join(__dirname, '../.env.local') });

interface TestResult {
    test: string;
    status: 'PASS' | 'FAIL';
    message: string;
    details?: any;
}

class DatabaseTester {
    private pool: Pool;
    private results: TestResult[] = [];

    constructor() {
        if (!process.env.DATABASE_URL) {
            throw new Error('DATABASE_URL not found in environment variables');
        }

        this.pool = new Pool({
            connectionString: process.env.DATABASE_URL,
            max: 5,
            idleTimeoutMillis: 30000,
            connectionTimeoutMillis: 10000,
        });
    }

    private addResult(test: string, status: 'PASS' | 'FAIL', message: string, details?: any) {
        this.results.push({ test, status, message, details });
        const color = status === 'PASS' ? '\x1b[32m' : '\x1b[31m';
        const reset = '\x1b[0m';
        console.log(`${color}[${status}]${reset} ${test}: ${message}`);
        if (details) {
            console.log(`       Details: ${JSON.stringify(details, null, 2)}`);
        }
    }

    async testConnection(): Promise<void> {
        try {
            const client = await this.pool.connect();
            const result = await client.query('SELECT NOW() as current_time, version() as postgres_version');
            client.release();
            
            this.addResult(
                'Database Connection',
                'PASS',
                'Successfully connected to database',
                {
                    currentTime: result.rows[0].current_time,
                    version: result.rows[0].postgres_version.split(' ')[0] + ' ' + result.rows[0].postgres_version.split(' ')[1]
                }
            );
        } catch (error) {
            this.addResult(
                'Database Connection',
                'FAIL',
                'Failed to connect to database',
                { error: error instanceof Error ? error.message : String(error) }
            );
        }
    }

    async testTables(): Promise<void> {
        try {
            const client = await this.pool.connect();
            const result = await client.query(`
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_type = 'BASE TABLE'
                ORDER BY table_name
            `);
            client.release();

            const expectedTables = ['subscriptions', 'usage_events', 'audit_logs'];
            const existingTables = result.rows.map(row => row.table_name);
            const missingTables = expectedTables.filter(table => !existingTables.includes(table));

            if (missingTables.length === 0) {
                this.addResult(
                    'Database Tables',
                    'PASS',
                    'All required tables exist',
                    { tables: existingTables }
                );
            } else {
                this.addResult(
                    'Database Tables',
                    'FAIL',
                    'Missing required tables',
                    { missing: missingTables, existing: existingTables }
                );
            }
        } catch (error) {
            this.addResult(
                'Database Tables',
                'FAIL',
                'Failed to check tables',
                { error: error instanceof Error ? error.message : String(error) }
            );
        }
    }

    async testIndexes(): Promise<void> {
        try {
            const client = await this.pool.connect();
            const result = await client.query(`
                SELECT indexname, tablename 
                FROM pg_indexes 
                WHERE schemaname = 'public'
                AND indexname LIKE 'idx_%'
                ORDER BY tablename, indexname
            `);
            client.release();

            const indexes = result.rows;
            
            if (indexes.length >= 8) { // We expect at least 8 custom indexes
                this.addResult(
                    'Database Indexes',
                    'PASS',
                    `Found ${indexes.length} custom indexes`,
                    { count: indexes.length }
                );
            } else {
                this.addResult(
                    'Database Indexes',
                    'FAIL',
                    `Only found ${indexes.length} indexes, expected at least 8`,
                    { indexes: indexes.map(idx => `${idx.tablename}.${idx.indexname}`) }
                );
            }
        } catch (error) {
            this.addResult(
                'Database Indexes',
                'FAIL',
                'Failed to check indexes',
                { error: error instanceof Error ? error.message : String(error) }
            );
        }
    }

    async testFunctions(): Promise<void> {
        try {
            const client = await this.pool.connect();
            const result = await client.query(`
                SELECT routine_name 
                FROM information_schema.routines 
                WHERE routine_schema = 'public' 
                AND routine_type = 'FUNCTION'
                ORDER BY routine_name
            `);
            client.release();

            const expectedFunctions = ['get_current_month_usage', 'get_usage_for_period', 'update_updated_at_column'];
            const existingFunctions = result.rows.map(row => row.routine_name);
            const missingFunctions = expectedFunctions.filter(func => !existingFunctions.includes(func));

            if (missingFunctions.length === 0) {
                this.addResult(
                    'Database Functions',
                    'PASS',
                    'All required functions exist',
                    { functions: existingFunctions }
                );
            } else {
                this.addResult(
                    'Database Functions',
                    'FAIL',
                    'Missing required functions',
                    { missing: missingFunctions, existing: existingFunctions }
                );
            }
        } catch (error) {
            this.addResult(
                'Database Functions',
                'FAIL',
                'Failed to check functions',
                { error: error instanceof Error ? error.message : String(error) }
            );
        }
    }

    async testSampleData(): Promise<void> {
        try {
            const client = await this.pool.connect();
            const result = await client.query('SELECT COUNT(*) as count FROM subscriptions');
            client.release();

            const count = parseInt(result.rows[0].count);
            
            if (count > 0) {
                this.addResult(
                    'Sample Data',
                    'PASS',
                    `Found ${count} subscription records`,
                    { count }
                );
            } else {
                this.addResult(
                    'Sample Data',
                    'FAIL',
                    'No sample data found in subscriptions table',
                    { count: 0 }
                );
            }
        } catch (error) {
            this.addResult(
                'Sample Data',
                'FAIL',
                'Failed to check sample data',
                { error: error instanceof Error ? error.message : String(error) }
            );
        }
    }

    async testUsageFunction(): Promise<void> {
        try {
            const client = await this.pool.connect();
            
            // Get a subscription ID for testing
            const subResult = await client.query('SELECT id FROM subscriptions LIMIT 1');
            if (subResult.rows.length === 0) {
                this.addResult(
                    'Usage Function Test',
                    'FAIL',
                    'No subscriptions found for testing usage function',
                    {}
                );
                client.release();
                return;
            }

            const subscriptionId = subResult.rows[0].id;
            const result = await client.query('SELECT get_current_month_usage($1) as usage', [subscriptionId]);
            client.release();

            const usage = parseInt(result.rows[0].usage);
            
            this.addResult(
                'Usage Function Test',
                'PASS',
                `Usage function working correctly`,
                { subscriptionId, currentUsage: usage }
            );
        } catch (error) {
            this.addResult(
                'Usage Function Test',
                'FAIL',
                'Failed to test usage function',
                { error: error instanceof Error ? error.message : String(error) }
            );
        }
    }

    async runAllTests(): Promise<boolean> {
        console.log('\x1b[36m=================================================================\x1b[0m');
        console.log('\x1b[36mDatabase Connection Test Suite\x1b[0m');
        console.log('\x1b[36m=================================================================\x1b[0m');
        console.log();

        await this.testConnection();
        await this.testTables();
        await this.testIndexes();
        await this.testFunctions();
        await this.testSampleData();
        await this.testUsageFunction();

        console.log();
        console.log('\x1b[36m=================================================================\x1b[0m');
        console.log('\x1b[36mTest Summary\x1b[0m');
        console.log('\x1b[36m=================================================================\x1b[0m');

        const passed = this.results.filter(r => r.status === 'PASS').length;
        const failed = this.results.filter(r => r.status === 'FAIL').length;
        const total = this.results.length;

        console.log(`Total Tests: ${total}`);
        console.log(`\x1b[32mPassed: ${passed}\x1b[0m`);
        console.log(`\x1b[31mFailed: ${failed}\x1b[0m`);

        if (failed > 0) {
            console.log();
            console.log('\x1b[31mFailed Tests:\x1b[0m');
            this.results
                .filter(r => r.status === 'FAIL')
                .forEach(r => console.log(`  - ${r.test}: ${r.message}`));
        }

        await this.pool.end();
        return failed === 0;
    }
}

// Main execution
async function main() {
    try {
        const tester = new DatabaseTester();
        const success = await tester.runAllTests();
        process.exit(success ? 0 : 1);
    } catch (error) {
        console.error('\x1b[31m[ERROR]\x1b[0m Failed to initialize database tester:', error);
        process.exit(1);
    }
}

main();
