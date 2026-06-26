const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');

// Define the route to retrieve student information
router.get('/students', studentController.getAllStudents);

module.exports = router;
