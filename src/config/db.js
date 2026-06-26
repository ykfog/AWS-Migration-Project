
const mysql = require('mysql2/promise');

// Create a connection pool to the RDS instance
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'admin',
    password: process.env.DB_PASSWORD || 'SecurePassword2026!',
    database: process.env.DB_NAME || 'app_database',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

module.exports = pool;
