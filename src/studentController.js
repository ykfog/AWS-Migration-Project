const db = require('../config/db');

exports.getAllStudents = async (req, res) => {
    try {
        // Query the RDS database
        const [rows] = await db.query('SELECT * FROM students');
        
        res.json({
            status: 'success',
            results: rows.length,
            data: rows
        });
    } catch (error) {
        // If the database isn't connected yet, return a safe mock response
        console.warn('Database not connected yet. Returning mock data.');
        res.status(200).json({
            status: 'success',
            message: 'Connected to App Tier. Database connection pending.',
            data: [
                { id: 1, name: "Student 1", cohort: "2026" },
                { id: 2, name: "Student 2", cohort: "2026" }
            ]
        });
    }
};
