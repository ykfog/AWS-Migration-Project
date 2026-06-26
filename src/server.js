require('dotenv').config();
const express = require('express');
const apiRoutes = require('./routes/api');

const app = express();
const port = process.env.PORT || 3000;

// Middleware to parse JSON requests
app.use(express.json());

// AWS Application Load Balancer Health Check Endpoint
app.get('/health', (req, res) => {
    res.status(200).send('Healthy');
});

// Mount the API routes
app.use('/api', apiRoutes);

// Start the server
app.listen(port, () => {
    console.log(`🚀 Secure Legacy Application running on port ${port}`);
});
